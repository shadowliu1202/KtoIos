import Foundation
import sharedbu

class P2PMyBetAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getDetail(id: String) -> SingleWrapper<ResponseItem<RecordDetailBean_>> {
        httpClient.request(
            path: "/p2p/api/wager/mybet/detail",
            method: .get,
            task: .urlParameters(["wagerId": id])
        )
        .asReaktiveResponseItem(serial: RecordDetailBean_.companion.serializer())
    }
}
