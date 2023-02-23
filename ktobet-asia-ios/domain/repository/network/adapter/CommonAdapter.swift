import Foundation
import SharedBu

class CommonAdapter: CommonProtocol {
  private var bankAPI: BankApi!

  init(_ bankAPI: BankApi) {
    self.bankAPI = bankAPI
  }

  func getBanks() -> SingleWrapper<ResponseList<BankBean>> {
    bankAPI.getBanks().asReaktiveResponseList(serial: BankBean.companion.serializer())
  }
}
