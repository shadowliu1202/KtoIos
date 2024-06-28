import Foundation
import sharedbu

class CasinoMyBetAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getDetail(id: String) -> SingleWrapper<ResponseItem<RecordDetailBean>> {
        httpClient
            .request(
                path: "/casino/api/v2/wager/mybet/detail",
                method: .get,
                task: .urlParameters(["wagerId": id])
            )
            .asReaktiveResponseItem(serial: RecordDetailBean.companion.serializer())
    }
}
