import Foundation
import SharedBu

class CasinoAdapter: CasinoProtocol {
  private let casinoApi: CasinoApi!

  init(_ casinoApi: CasinoApi) {
    self.casinoApi = casinoApi
  }

  func getTagWithGameCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
    casinoApi.getCasinoTagsWithCount().asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
  }
}
