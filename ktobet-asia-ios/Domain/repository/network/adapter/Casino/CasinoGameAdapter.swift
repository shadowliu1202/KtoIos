import Foundation
import sharedbu

class CasinoGameAdapter: CasinoGameProtocol {
  private let casinoGameAPI: CasinoGameAPI
  
  init(_ casinoGameAPI: CasinoGameAPI) {
    self.casinoGameAPI = casinoGameAPI
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
  
  func getLobbyStatus() -> SingleWrapper<ResponseList<LobbyBean>> {
    fatalError()
  }
  
  func getPopularKeywords() -> SingleWrapper<ResponseList<NSString>> {
    fatalError()
  }
  
  func getTagWithGameCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
    casinoGameAPI
      .getCasinoTagsWithCount()
      .asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
  }
  
  func removeFavoriteCasino(id _: String) -> CompletableWrapper {
    fatalError()
  }
  
  func searchGame(keyword_ _: String) -> SingleWrapper<ResponseList<CasinoGameBean>> {
    fatalError()
  }
}
