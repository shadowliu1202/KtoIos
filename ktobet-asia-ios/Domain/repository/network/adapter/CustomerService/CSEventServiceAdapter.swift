import Foundation
import RxSwift
import SharedBu

class CSEventServiceAdapter: CSEventService {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func provide(token: String) -> CSEventSubject {
    CSSignalRClient(
      token,
      httpClient)
  }
}
