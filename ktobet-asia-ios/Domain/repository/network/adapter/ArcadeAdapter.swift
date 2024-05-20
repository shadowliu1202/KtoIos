import Foundation
import sharedbu

class ArcadeAdapter: ArcadeProtocol {
    private let arcadeApi: ArcadeApi!

    init(_ arcadeApi: ArcadeApi) {
        self.arcadeApi = arcadeApi
    }

    func getTagWithGameCount() -> SingleWrapper<ResponseList<FilterTagBean>> {
        arcadeApi.getArcadeTagsWithCount().asReaktiveResponseList(serial: FilterTagBean.companion.serializer())
    }
}
