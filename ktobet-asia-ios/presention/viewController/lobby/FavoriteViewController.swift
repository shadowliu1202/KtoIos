import RxCocoa
import RxSwift
import SharedBu
import UIKit

class FavoriteViewController: DisplayProduct {
  @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
  @IBOutlet weak var emptyViewAddButton: UIButton!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)
  private var gameData: [WebGameWithDuplicatable] = [] {
    didSet {
      self.switchContent(gameData)
      self.reloadGameData(gameData)
    }
  }

  @IBOutlet weak var emptyView: UIView!
  var viewModel: DisplayProductViewModel?
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_favorite"))
    initUI()
    dataBinding()
  }

  private func initUI() {
    gamesCollectionView.rx
      .observe(\.contentSize)
      .subscribe(onNext: { [weak self] in
        let space: CGFloat = 30
        let bottomPadding: CGFloat = 96
        self?.scrollViewContentHeight.constant = $0.height + space + bottomPadding
      })
      .disposed(by: disposeBag)
  }

  private func dataBinding() {
    viewModel?.getFavorites()
    emptyViewAddButton.rx.touchUpInside.bind { _ in
      NavigationManagement.sharedInstance.popViewController()
    }.disposed(by: disposeBag)
    viewModel?.favoriteProducts()
      .catchError({ [weak self] error -> Observable<[WebGameWithDuplicatable]> in
        switch error {
        case KTOError.EmptyData:
          self?.switchContent()
        default:
          self?.handleErrors(error)
        }
        return Observable.just([])
      }).subscribe(onNext: { [weak self] games in
        self?.gameData = games
      }).disposed(by: self.disposeBag)
  }

  private func switchContent(_ games: [WebGameWithProperties]? = nil) {
    if let items = games, items.count > 0 {
      self.gamesCollectionView.isHidden = false
      self.emptyView.isHidden = true
    }
    else {
      self.gamesCollectionView.isHidden = true
      self.emptyView.isHidden = false
    }
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
    viewModel!.getGameProductType()
  }
}
