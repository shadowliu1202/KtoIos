import Foundation
import sharedbu

class CasinoGameAdapter: CasinoGameProtocol {
  private let httpClient: HttpClient
  
  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }
  
  func addFavoriteCasino(id _: String) -> CompletableWrapper {
    fatalError()
  }
  
  func filterGame(sortBy _: Int32, map _: [String: String]) -> SingleWrapper<ResponseList<CasinoGameBean>> {
    fatalError()
  }
  
  func getFavoriteGame() -> SingleWrapper<ResponseList<CasinoGameBean>> {
    fatalError()
  }
  
  func getGameUrl(id _: String, url _: String) -> SingleWrapper<ResponseItem<NSString>> {
    fatalError()
  }
  
  func getLobbyTop() -> SingleWrapper<ResponseList<LobbyBean>> {
    httpClient
      .requestJsonString(path: "/casino/api/game/lobby/top", method: .get)
      .asReaktiveResponseList(serial: LobbyBean.companion.serializer())
  }
  
  func getPopularKeywords() -> SingleWrapper<ResponseList<NSString>> {
    fatalError()
  }
  
  func getTagWithGameCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
    httpClient
      .requestJsonString(path: "casino/api/game/mobile/tag-with-gamecount", method: .get)
      .asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
  }
  
  func removeFavoriteCasino(id _: String) -> CompletableWrapper {
    fatalError()
  }
  
  func searchGame(keyword _: String) -> SingleWrapper<ResponseList<CasinoGameBean>> {
    fatalError()
  }
}
