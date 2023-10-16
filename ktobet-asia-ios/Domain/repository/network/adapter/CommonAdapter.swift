import Foundation
import sharedbu

class CommonAdapter: CommonProtocol {
  private let commonAPI: CommonAPI

  init(_ commonAPI: CommonAPI) {
    self.commonAPI = commonAPI
  }

  func getBanks() -> SingleWrapper<ResponseList<BankBean>> {
    commonAPI
      .getBanks()
      .asReaktiveResponseList(serial: BankBean.companion.serializer())
  }
}
