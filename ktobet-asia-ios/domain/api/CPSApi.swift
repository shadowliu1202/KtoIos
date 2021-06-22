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
}

