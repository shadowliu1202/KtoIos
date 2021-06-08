import Foundation
import RxSwift
import SharedBu
import Moya


class CPSApi {
    private var httpClient : HttpClient!
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func createCryptoDeposit() -> Single<ResponseData<CryptoDepositReceipt>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/online-deposit-crypto",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<CryptoDepositReceipt>.self)
    }
}

