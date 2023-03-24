import Foundation
import RxSwift
import SharedBu

class CommonAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getBanks() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/init/bank",
          method: .get))
  }
}
