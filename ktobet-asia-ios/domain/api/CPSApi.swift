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
    
    var baseUrl: URL {
        return httpClient.host
    }
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func createCryptoDeposit(cryptoDepositRequest: CryptoDepositRequest) -> Single<ResponseData<CryptoDepositReceipt>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/deposit/online-deposit-crypto",
                               method: .post,
                               task: .requestJSONEncodable(cryptoDepositRequest),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<CryptoDepositReceipt>.self)
    }
    
    func getCryptoBankCard() -> Single<ResponseData<PayloadPage<CryptoBankCardBean>>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/crypto-bank-card",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<PayloadPage<CryptoBankCardBean>>.self)
    }
    
    func createCryptoBankCard(cryptoBankCardRequest: CryptoBankCardRequest) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.host,
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
    
    func getCryptoExchangeRate(_ cryptoCurrencyId: Int32) -> Single<NonNullResponseData<Double>> {
        let target = GetAPITarget(service: self.url("api/crypto-currency-rate/\(cryptoCurrencyId)"))
        return httpClient.request(target).map(NonNullResponseData<Double>.self)
    }
    
    func createCryptoWithdrawal(request: CryptoWithdrawalRequest) -> Single<ResponseData<String>> {
        let target = PostAPITarget(service: self.url("api/withdrawal/crypto"), parameters: request)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func deleteBankCards(bankCardId: [String: String]) -> Completable {
        let target = DeleteAPITarget(service: self.url("api/crypto-bank-card")).parameters(bankCardId)
        return httpClient.request(target).asCompletable()
    }
    
    func getCryptoCurrency() -> Single<ResponseData<CryptoCurrencyBean>> {
        let target = GetAPITarget(service: self.url("api/deposit/crypto-currency"))
        return httpClient.request(target).map(ResponseData<CryptoCurrencyBean>.self)
    }

    func getCryptoLimitations() -> Single<ResponseData<[CryptoLimitBean]>> {
        let target = GetAPITarget(service: self.url("api/withdrawal/each-crypto-limit"))
        return httpClient.request(target).map(ResponseData<[CryptoLimitBean]>.self)
    }
    
    // MARK: New
    func getCryptoCurrency() -> Single<String> {
        let target = GetAPITarget(service: self.url("api/deposit/crypto-currency"))
        return httpClient.requestJsonString(target)
    }
    
    func onlineDepositCrypto(cryptoDepositRequest: CryptoDepositRequest) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/deposit/online-deposit-crypto",
                               method: .post,
                               task: .requestJSONEncodable(cryptoDepositRequest),
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func getCryptoExchangeFeeSettingString(cryptoExchange: Int32 = 1) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/deposit/crypto-exchange/\(cryptoExchange)/fee-setting",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
}

