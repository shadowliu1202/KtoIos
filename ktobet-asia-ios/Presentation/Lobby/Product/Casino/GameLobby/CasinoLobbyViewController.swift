import RxCocoa
import RxSwift
import sharedbu
import UIKit

class CasinoLobbyViewController: DisplayProduct {
  @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)
  var viewModel: CasinoViewModel!
  var lobby: CasinoDTO.Lobby!
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: lobby.name)
    initUI()
    dataBinding()
  }

  private func initUI() {
    gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    gamesCollectionView.registerCellFromNib(WebGameItemCell.className)
  }

  private func dataBinding() {
    gamesCollectionView.dataSource = gameDataSourceDelegate
    gamesCollectionView.delegate = gameDataSourceDelegate

    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)
    
    viewModel.getLobbyGames(lobbyType: lobby.type)
      .subscribe(onNext: { [weak self] games in
        self?.reloadGameData(games)
      })
      .disposed(by: disposeBag)

    viewModel.refreshLobbyGames()

    bindPlaceholder(.casinoLobby, with: viewModel)
  }

  // MARK: KVO
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context _: UnsafeMutableRawPointer?)
  {
    if keyPath == "contentSize", let newvalue = change?[.newKey] {
      if let obj = object as? UICollectionView, obj == gamesCollectionView {
        let space: CGFloat = 30
        scrollViewContentHeight.constant = (newvalue as! CGSize).height + space
      }
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
    .casino
  }
}
