import RxCocoa
import RxSwift
import sharedbu
import UIKit

enum GameState {
  case active
  case inactive(String, UIImage)
  case maintenance(String, UIImage)
}

extension WebGameWithProperties {
  var isActive: Bool {
    switch gameState() {
    case .active:
      return true
    default:
      return false
    }
  }

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
  func toggleFavorite(
    _ game: WebGameWithDuplicatable,
    onCompleted: @escaping (FavoriteAction) -> Void,
    onError: @escaping (Error) -> Void)
}

protocol ProductGoWebGameVCProtocol: AnyObject {
  func getProductViewModel() -> ProductWebGameViewModelProtocol?
}

protocol WebGameViewCallback: AnyObject {
  func gameDisappear()
}

typealias ProductViewModel = ProductFavoriteViewModelProtocol & ProductSearchViewModelProtocol & ProductWebGameViewModelProtocol

protocol ProductFavoriteViewModelProtocol {
  func favoriteProducts() -> Observable<[WebGameWithDuplicatable]>
  func toggleFavorite(
    game: WebGameWithDuplicatable,
    onCompleted: @escaping (FavoriteAction) -> Void,
    onError: @escaping (Error) -> Void)
}

protocol ProductSearchViewModelProtocol {
  func clearSearchResult()
  func searchSuggestion() -> Single<[String]>
  func triggerSearch(_ text: String?)
  func searchResult() -> Observable<Event<[WebGameWithDuplicatable]>>
}

protocol ProductWebGameViewModelProtocol {
  var loadingWebTracker: ActivityIndicator { get }
  var placeholderTracker: ActivityIndicator { get }

  var webGameResultDriver: Driver<WebGameResult> { get }

  func getGameProduct() -> String
  func getGameProductType() -> ProductType

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult>

  func fetchGame(_ game: WebGame)
}

extension ProductWebGameViewModelProtocol {
  var placeholderTracker: ActivityIndicator { .init() }

  func configFetchGame(
    _ game: WebGame,
    resultSubject: PublishSubject<WebGameResult>,
    errorSubject: PublishSubject<Error>)
    -> Disposable
  {
    checkBonusAndCreateGame(game)
      .trackOnDispose(loadingWebTracker)
      .subscribe(onNext: {
        resultSubject.onNext($0)
      }, onError: {
        errorSubject.onNext($0)
      })
  }
}
