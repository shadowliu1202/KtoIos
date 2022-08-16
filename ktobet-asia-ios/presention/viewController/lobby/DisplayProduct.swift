import UIKit
import SharedBu
import RxSwift

typealias DisplayProductViewModel = ProductFavoriteViewModelProtocol & ProductWebGameViewModelProtocol
typealias DisplayProduct = DisplayGameCollectionBaseViewController & ProductBaseCollection

protocol ProductBaseCollection: AnyObject {
    func setCollectionView() -> UICollectionView
    func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate
    func setViewModel() -> DisplayProductViewModel?
}

class DisplayGameCollectionBaseViewController: ProductsViewController, ProductVCProtocol {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    func setup() {
        guard let `self` = self as? DisplayProduct else { return }
        let collectionView = self.setCollectionView()
        collectionView.registerCellFromNib(WebGameItemCell.className)
        collectionView.delegate = self.setProductGameDataSourceDelegate()
        collectionView.dataSource = self.setProductGameDataSourceDelegate()
    }
    
    func reloadGameData(_ games: [WebGameWithDuplicatable]) {
        guard let `self` = self as? DisplayProduct else { return }
        self.setProductGameDataSourceDelegate().setGames(games)
        self.setCollectionView().reloadData()
    }
    
    func toggleFavorite(_ game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction) -> (), onError: @escaping (Error) -> ()) {
        guard let `self` = self as? DisplayProduct else { return }
        self.setViewModel()?.toggleFavorite(game: game, onCompleted: onCompleted, onError: onError)
    }
    
    func getProductViewModel() -> ProductWebGameViewModelProtocol? {
        guard let `self` = self as? DisplayProduct else { return nil }
        return self.setViewModel()
    }
}
