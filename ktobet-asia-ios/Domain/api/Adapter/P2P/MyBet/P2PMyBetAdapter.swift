import Foundation
import sharedbu

class P2PMyBetAdapter: P2PMyBetProtocol {
    private let p2pMyBetAPI: P2PMyBetAPI

    init(_ p2pMyBetAPI: P2PMyBetAPI) {
        self.p2pMyBetAPI = p2pMyBetAPI
    }

    func getDetail(id: String) -> SingleWrapper<ResponseItem<RecordDetailBean_>> {
        p2pMyBetAPI.getDetail(id: id)
    }
}
