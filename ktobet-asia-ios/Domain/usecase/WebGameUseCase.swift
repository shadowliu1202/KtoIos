import Foundation
import RxSwift
import SharedBu

typealias WebGameUseCase = WebGameFavoriteUseCase &
  WebGameSearchUseCase &
  WebGameCreateUseCase

protocol WebGameFavoriteUseCase {
  func addFavorite(game: WebGameWithDuplicatable) -> Completable
  func removeFavorite(game: WebGameWithDuplicatable) -> Completable
  func getFavorites() -> Observable<[WebGameWithDuplicatable]>
}

protocol WebGameSearchUseCase {
  func getSuggestKeywords() -> Single<[String]>
  func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]>
}

protocol WebGameCreateUseCase: AnyObject {
  var webGameCreateRepository: WebGameCreateRepository { get }
  var promotionRepository: PromotionRepository { get }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult>
}

extension WebGameCreateUseCase {
  func createGame(_ game: WebGame) -> Observable<WebGameResult> {
    webGameCreateRepository
      .createGame(gameId: game.gameId)
      .map { WebGameResult.loaded(gameName: game.gameName, $0) }
      .asObservable()
  }

  private func isLockedOrCalculating(gameName: String) -> Observable<WebGameResult> {
    let getLockedDetail = promotionRepository
      .getLockedBonusDetail()
      .asObservable()
      .map {
        WebGameResult.lockedBonus(gameName: gameName, $0)
      }

    return promotionRepository
      .isLockedBonusCalculating()
      .asObservable()
      .flatMap {
        if $0 {
          return Observable.just(WebGameResult.bonusCalculating(gameName: gameName))
        }
        else {
          return getLockedDetail
        }
      }
  }

  func checkBonusAndCreateGame(_ game: WebGame) -> Observable<WebGameResult> {
    guard let withProperties = game as? WebGameWithProperties
    else {
      return createGame(game)
    }

    guard withProperties.isActive
    else {
      return .just(.inactive)
    }

    if withProperties.requireNoBonusLock {
      return promotionRepository
        .hasAccountLockedBonus()
        .asObservable()
        .flatMap { [unowned self] locked in
          if locked {
            return self.isLockedOrCalculating(gameName: withProperties.gameName)
          }
          else {
            return self.createGame(withProperties)
          }
        }
    }
    else {
      return createGame(withProperties)
    }
  }
}

enum WebGameResult {
  case inactive
  case loaded(gameName: String, URL?)
  case bonusCalculating(gameName: String)
  case lockedBonus(gameName: String, TurnOverDetail)
}

class WebGameUseCaseImpl: WebGameUseCase {
  let promotionRepository: PromotionRepository
  let webGameRepository: WebGameRepository

  var webGameCreateRepository: WebGameCreateRepository { webGameRepository }

  init(
    webGameRepository: WebGameRepository,
    promotionRepository: PromotionRepository)
  {
    self.webGameRepository = webGameRepository
    self.promotionRepository = promotionRepository
  }

  func addFavorite(game: WebGameWithDuplicatable) -> Completable {
    webGameRepository.addFavorite(game: game)
  }

  func removeFavorite(game: WebGameWithDuplicatable) -> Completable {
    webGameRepository.removeFavorite(game: game)
  }

  func getFavorites() -> Observable<[WebGameWithDuplicatable]> {
    webGameRepository.getFavorites()
  }

  func getSuggestKeywords() -> Single<[String]> {
    webGameRepository.getSuggestKeywords()
  }

  func searchGames(keyword: SearchKeyword) -> Observable<[WebGameWithDuplicatable]> {
    if keyword.isSearchPermitted() {
      return webGameRepository.searchGames(keyword: keyword)
    }
    return Observable.just([])
  }
}
