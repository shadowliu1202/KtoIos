import Foundation
import SharedBu

class CasinoGameAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }
  
  func getCasinoTagsWithCount() -> Single<String> {
    httpClient
      .requestJsonString(path: "casino/api/game/mobile/tag-with-gamecount", method: .get)
  }
}
