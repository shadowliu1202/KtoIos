import Foundation
import SharedBu

class CasinoMyBetAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }
  
  func getDetail(id: String) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "/casino/api/v2/wager/mybet/detail",
        method: .get,
        task: .requestParameters(
          parameters: [
            "wagerId": id
          ]))
  }
}
