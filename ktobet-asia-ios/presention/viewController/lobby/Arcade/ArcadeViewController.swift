import RxSwift
import SharedBu
import UIKit

class ArcadeViewController: DisplayProduct {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tagsStackView: GameTagStackView!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  @IBOutlet private weak var scrollViewContentHeight: NSLayoutConstraint!

  private var disposeBag = DisposeBag()

  var viewModel = Injectable.resolveWrapper(ArcadeViewModel.self)
  var barButtonItems: [UIBarButtonItem] = []

  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Logger.shared.info("\(type(of: self)) viewDidLoad.")
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
    initUI()
    dataBinding()
  }

  private func initUI() {
    gamesCollectionView.rx
      .observe(\.contentSize)
      .asDriverLogError()
      .map { [weak self] size -> CGFloat in
        guard let self else { return 0 }
        let aboveHeight = self.titleLabel.frame.size.height + self.tagsStackView.frame.size.height
        let space: CGFloat = 8 + 30 + 24 + 20

        return size.height + aboveHeight + space
      }
      .drive(onNext: { [unowned self] in
        self.scrollViewContentHeight.constant = $0
      })
      .disposed(by: disposeBag)
  }

  private func dataBinding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        if $0.isMaintenance() {
          NavigationManagement.sharedInstance.goTo(productType: .arcade, isMaintenance: true)
        }
        else {
          self?.handleErrors($0)
        }
      })
      .disposed(by: disposeBag)

    bindWebGameResult(with: viewModel)

    viewModel
      .gameSource
      .subscribe(onNext: { [weak self] games in
        self?.reloadGameData(games)
      })
      .disposed(by: disposeBag)

    bindPlaceholder(.arcade, with: viewModel)
    
    viewModel.tagStates
      .subscribe(onNext: { [unowned self] data in
        self.tagsStackView.initialize(
          recommend: data.0,
          new: data.1,
          allTagClick: { self.viewModel.selectAll() },
          recommendClick: { self.viewModel.toggleRecommend() },
          newClick: { self.viewModel.toggleNew() })
      })
      .disposed(by: self.disposeBag)
  }

  // MARK: ProductBaseCollection
  func setCollectionView() -> UICollectionView {
    gamesCollectionView
  }

  func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate {
    gameDataSourceDelegate
  }

  func setViewModel() -> DisplayProductViewModel? {
    viewModel
  }

  override func setProductType() -> ProductType {
    .arcade
  }
}

extension ArcadeViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender {
    case is RecordBarButtonItem:
      guard
        let betSummaryViewController = self.storyboard?
          .instantiateViewController(withIdentifier: "ArcadeSummaryViewController") as? ArcadeSummaryViewController
      else { return }
      self.navigationController?.pushViewController(betSummaryViewController, animated: true)
    case is FavoriteBarButtonItem:
      guard
        let favoriteViewController = UIStoryboard(name: "Product", bundle: nil)
          .instantiateViewController(withIdentifier: "FavoriteViewController") as? FavoriteViewController else { return }
      favoriteViewController.viewModel = self.viewModel
      self.navigationController?.pushViewController(favoriteViewController, animated: true)
    case is SearchButtonItem:
      guard
        let searchViewController = UIStoryboard(name: "Product", bundle: nil)
          .instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else { return }
      searchViewController.viewModel = self.viewModel
      self.navigationController?.pushViewController(searchViewController, animated: true)
    default: break
    }
  }
}
