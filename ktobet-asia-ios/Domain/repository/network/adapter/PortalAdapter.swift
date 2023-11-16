import Foundation
import sharedbu

class PortalAdapter: PortalProtocol {
  private let httpClient: HttpClient
  
  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }
  
  func getOTPStatus() -> SingleWrapper<ResponseItem<OTPStatusBean>> {
    httpClient
      .requestJsonString(path: "api/init/portal-maintenance", method: .get)
      .asReaktiveResponseItem(serial: OTPStatusBean.companion.serializer())
  }
}
