import Foundation
import RxSwift
import SharedBu

class CSEventServiceAdapter: CSEventService {
  private let httpClient: HttpClient
  private let customerServiceProtocol: CustomerServiceProtocol

  init(
    _ httpClient: HttpClient,
    _ customerServiceProtocol: CustomerServiceProtocol)
  {
    self.httpClient = httpClient
    self.customerServiceProtocol = customerServiceProtocol
  }

  func provide(token: String) -> CSEventSubject {
    CSSignalRClient(
      token,
      httpClient,
      customerServiceProtocol)
  }
}
