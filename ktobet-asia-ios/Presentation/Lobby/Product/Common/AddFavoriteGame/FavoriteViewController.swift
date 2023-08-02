import RxCocoa
import RxSwift
import SharedBu
import UIKit

class FavoriteViewController: DisplayProduct {
  @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)
  private var gameData: [WebGameWithDuplicatable] = [] {
    didSet {
      self.switchContent(gameData)
      self.reloadGameData(gameData)
    }
  }

  private var favoriteGameEmptyStateView: FavoriteGameEmptyStateView!
  
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
    
    initFavoriteGameEmptyStateView()
  }
  
  private func initFavoriteGameEmptyStateView() {
    favoriteGameEmptyStateView = FavoriteGameEmptyStateView()

    view.addSubview(favoriteGameEmptyStateView)
    
    favoriteGameEmptyStateView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func dataBinding() {
    favoriteGameEmptyStateView.addFavoriteButton.rx
      .touchUpInside
      .bind { _ in
        NavigationManagement.sharedInstance.popViewController()
      }
      .disposed(by: disposeBag)

    viewModel?.favoriteProducts()
      .catch { [unowned self] in
        handleErrors($0)
        return Observable<[WebGameWithDuplicatable]>.never()
      }
      .subscribe(onNext: { [unowned self] in gameData = $0 })
      .disposed(by: disposeBag)

    guard let viewModel else { return }

    bindPlaceholder(.favorite, with: viewModel)
  }

  private func switchContent(_ games: [WebGameWithProperties]) {
    gamesCollectionView.isHidden = games.count < 0
    favoriteGameEmptyStateView.isHidden = games.count > 0
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
