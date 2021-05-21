import UIKit
import RxSwift
import share_bu

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

protocol ProductFavoriteVCProtocol: class {
    func toggleFavorite(_ game: WebGameWithProperties, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->())
}

protocol ProductGoWebGameVCProtocol: class {
    func getProductViewModel() -> ProductWebGameViewModelProtocol?
}

typealias ProductViewModel = ProductFavoriteViewModelProtocol & ProductSearchViewModelProtocol & ProductWebGameViewModelProtocol

protocol ProductFavoriteViewModelProtocol {
    func getFavorites()
    func favoriteProducts() -> Observable<[WebGameWithProperties]>
    func toggleFavorite(game: WebGameWithProperties, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->())
}

protocol ProductSearchViewModelProtocol {
    func clearSearchResult()
    func searchSuggestion() -> Single<[String]>
    func triggerSearch(_ text: String?)
    func searchResult() -> Observable<Event<[WebGameWithProperties]>>
}

protocol ProductWebGameViewModelProtocol {
    func getGameProduct() -> String
    func createGame(gameId: Int32) -> Single<URL?>
}
