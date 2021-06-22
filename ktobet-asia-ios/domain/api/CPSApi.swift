import Foundation
import RxSwift
import SharedBu
import Moya


class CPSApi: ApiService {
    let prefixW = "api/withdrawal"
    let prefixD = "api/deposit"
    private var urlPath: String!
    
    private func url(_ u: String) -> Self {
        self.urlPath = u
        return self
    }
    private var httpClient : HttpClient!
    
    var surfixPath: String {
        return self.urlPath
    }
    
    var headers: [String : String]? {
        return httpClient.headers
    }
    
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
    
    func getCryptoBankCard() -> Single<ResponseData<PayloadPage<CryptoBankCardBean>>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/crypto-bank-card",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<PayloadPage<CryptoBankCardBean>>.self)
    }
    
    func createCryptoBankCard(cryptoBankCardRequest: CryptoBankCardRequest) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/crypto-bank-card",
                               method: .post,
                               task: .requestJSONEncodable(cryptoBankCardRequest),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getCryptoWithdrawalLimitTransactions() -> Single<NonNullResponseData<CryptoWithdrawalTransaction>> {
        let target = GetAPITarget(service: self.url("\(prefixW)/crypto-transaction-success-log"))
        return httpClient.request(target).map(NonNullResponseData<CryptoWithdrawalTransaction>.self)
    }
}

