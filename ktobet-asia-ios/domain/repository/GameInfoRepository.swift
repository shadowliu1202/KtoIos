import Foundation
import RxSwift
import SwiftyJSON

protocol GameInfoRepository {
  func getGameUrl() -> Single<URL>
}

class GameInfoRepositoryImpl: GameInfoRepository {
  private var httpClient: HttpClient!
  private var apiGame: GameApi!
  private var unknownError = NSError(domain: "unknown error", code: 99999, userInfo: ["": ""])
  private var disposeBag = DisposeBag()

  init(_ apiGame: GameApi, _ httpClient: HttpClient) {
    self.apiGame = apiGame
    self.httpClient = httpClient
  }

  func getGameUrl() -> Single<URL> {
    apiGame.getGameUrl()
  }
}
