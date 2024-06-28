import Foundation
import RxSwift
import sharedbu

class CommonAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getBanks() -> SingleWrapper<ResponseList<BankBean>> {
        httpClient.request(path: "api/init/bank", method: .get).asReaktiveResponseList(serial: BankBean.companion.serializer())
    }
}
