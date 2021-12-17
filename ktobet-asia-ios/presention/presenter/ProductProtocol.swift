import UIKit
import RxSwift
import SharedBu

enum GameState {
    case active
    case inactive(String, UIImage)
    case maintenance(String, UIImage)
}

extension WebGameWithProperties {
    func gameState() -> GameState {
        switch self.gameStatus {
        case .active:
            return .active
        case .inactive:
            return .inactive(Localize.string("product_game_removed"), UIImage(named: "game-off")!)
        case .maintenance:
            return .maintenance(Localize.string("product_under_maintenance"), UIImage(named: "game-maintainance")!)
        default:
            return .active
        }
    }
}

enum FavoriteAction {
    case add
    case remove
}

typealias ProductVCProtocol = ProductFavoriteVCProtocol & ProductGoWebGameVCProtocol

protocol ProductFavoriteVCProtocol: AnyObject {
    func toggleFavorite(_ game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->())
}

protocol ProductGoWebGameVCProtocol: AnyObject {
    func getProductViewModel() -> ProductWebGameViewModelProtocol?
}

protocol WebGameViewCallback: AnyObject {
    func gameDidDisappear()
}

typealias ProductViewModel = ProductFavoriteViewModelProtocol & ProductSearchViewModelProtocol & ProductWebGameViewModelProtocol

protocol ProductFavoriteViewModelProtocol {
    func getFavorites()
    func favoriteProducts() -> Observable<[WebGameWithDuplicatable]>
    func toggleFavorite(game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->())
}

protocol ProductSearchViewModelProtocol {
    func clearSearchResult()
    func searchSuggestion() -> Single<[String]>
    func triggerSearch(_ text: String?)
    func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>>
}

protocol ProductWebGameViewModelProtocol {
    func getGameProduct() -> String
    func createGame(gameId: Int32) -> Single<URL?>
}
