import UIKit
import RxSwift
import RxCocoa
import SharedBu

class CasinoLobbyViewController: DisplayProduct {
    
    @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    var viewModel: CasinoViewModel!
    var lobby: CasinoLobby!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: lobby.name)
        initUI()
        dataBinding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshLobbyGames()
    }
    
    private func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        gamesCollectionView.registerCellFromNib(WebGameItemCell.className)
    }
    
    private func dataBinding() {
        gamesCollectionView.dataSource = gameDataSourceDelegate
        gamesCollectionView.delegate = gameDataSourceDelegate
        viewModel.getLobbyGames(lobby: lobby.lobby)
            .catchError({ [weak self] (error) -> Observable<[CasinoGame]> in
                self?.handleErrors(error)
                return Observable.just([])
            }).subscribe(onNext: { [weak self] (games) in
                self?.reloadGameData(games)
            }).disposed(by: self.disposeBag)
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                let space: CGFloat = 30
                scrollViewContentHeight.constant = (newvalue as! CGSize).height + space
            }
        }
    }
    
    // MARK: ProductBaseCollection
    func setCollectionView() -> UICollectionView {
        return gamesCollectionView
    }
    
    func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate {
        return gameDataSourceDelegate
    }
    
    func setViewModel() -> DisplayProductViewModel? {
        return viewModel
    }
    
    override func setProductType() -> ProductType {
        .casino
    }
}
