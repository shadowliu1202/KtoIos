import Foundation
import SharedBu

class NumberGameAdapter: NumberGameProtocol {
  private let numberGameApi: NumberGameApi!

  init(_ numberGameApi: NumberGameApi) {
    self.numberGameApi = numberGameApi
  }

  func getTagWithGameCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
    numberGameApi.getNumberGameTagsWithCount().asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
  }
}
