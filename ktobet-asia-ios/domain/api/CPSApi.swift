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
    
    func sendAccountVerifyOTP(verifyRequest: AccountVerifyRequest) -> Single<ResponseData<Nothing>> {
        let target = PostAPITarget(service: self.url("api/crypto-bank-card/send-otp"), parameters: verifyRequest)
        return httpClient.request(target).map(ResponseData<Nothing>.self)
    }
    
    func verifyOTP(verifyOtp: OTPVerifyRequest) -> Single<ResponseData<Nothing>> {
        let target = PostAPITarget(service: self.url("api/crypto-bank-card/verify-otp"), parameters: verifyOtp)
        return httpClient.request(target).map(ResponseData<Nothing>.self)
    }
    
    func resendOTP(type: Int) -> Completable {
        let target = PostAPITarget(service: self.url("api/crypto-bank-card/resend-otp/\(type)"), parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func getCryptoExchangeRate(_ cryptoCurrencyId: Int) -> Single<NonNullResponseData<Double>> {
        let target = GetAPITarget(service: self.url("api/crypto-currency-rate/\(cryptoCurrencyId)"))
        return httpClient.request(target).map(NonNullResponseData<Double>.self)
    }
    
    func createCryptoWithdrawal(request: CryptoWithdrawalRequest) -> Single<ResponseData<String>> {
        let target = PostAPITarget(service: self.url("api/withdrawal/crypto"), parameters: request)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
}

