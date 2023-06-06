import Foundation
import Moya
import RxSwift
import SharedBu

class OldWithdrawalAPI: ApiService {
  private var urlPath: String!

  private func url(_ u: String) -> Self {
    self.urlPath = u
    return self
  }

  private var httpClient: HttpClient!

  var surfixPath: String {
    self.urlPath
  }

  var headers: [String: String]? {
    httpClient.headers
  }

  var baseUrl: URL {
    httpClient.host
  }

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getCryptoBankCard() -> Single<ResponseData<PayloadPage<CryptoBankCardBeanCodable>>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/crypto-bank-card",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<PayloadPage<CryptoBankCardBeanCodable>>.self)
  }

  func createCryptoBankCard(cryptoBankCardRequest: CryptoBankCardRequestCodable) -> Single<ResponseData<String>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/crypto-bank-card",
      method: .post,
      task: .requestJSONEncodable(cryptoBankCardRequest),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<String>.self)
  }

  func getCryptoWithdrawalLimitTransactions() -> Single<NonNullResponseData<CryptoWithdrawalTransaction>> {
    let target = GetAPITarget(service: self.url("api/withdrawal/crypto-transaction-success-log"))
    return httpClient.request(target).map(NonNullResponseData<CryptoWithdrawalTransaction>.self)
  }

  func sendAccountVerifyOTP(verifyRequest: AccountVerifyRequestCodable) -> Single<ResponseData<Nothing>> {
    let target = PostAPITarget(service: self.url("api/crypto-bank-card/send-otp"), parameters: verifyRequest)
    return httpClient.request(target).map(ResponseData<Nothing>.self)
  }

  func verifyOTP(verifyOtp: OTPVerifyRequestCodable) -> Single<ResponseData<Nothing>> {
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

  func createCryptoWithdrawal(request: CryptoWithdrawalRequestCodable) -> Single<ResponseData<String>> {
    let target = PostAPITarget(service: self.url("api/withdrawal/crypto"), parameters: request)
    return httpClient.request(target).map(ResponseData<String>.self)
  }

  func deleteBankCards(bankCardId: [String: String]) -> Completable {
    let target = DeleteAPITarget(service: self.url("api/crypto-bank-card")).parameters(bankCardId)
    return httpClient.request(target).asCompletable()
  }

  func getCryptoLimitations() -> Single<ResponseData<[CryptoLimitBeanCodable]>> {
    let target = GetAPITarget(service: self.url("api/withdrawal/each-crypto-limit"))
    return httpClient.request(target).map(ResponseData<[CryptoLimitBeanCodable]>.self)
  }

  func bindingImageWithWithdrawalRecord(displayId: String, uploadImagesData: WithdrawalImagesCodable) -> Completable {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/images/\(displayId)",
      method: .put,
      task: .requestJSONEncodable(uploadImagesData),
      header: httpClient.headers)
    return httpClient.request(target).asCompletable()
  }

  func getWithdrawalLimitation() -> Single<ResponseData<DailyWithdrawalLimits>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/limit-count",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<DailyWithdrawalLimits>.self)
  }

  func getWithdrawalRecords() -> Single<ResponseData<[WithdrawalRecordData]>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<[WithdrawalRecordData]>.self)
  }

  func getWithdrawalRecordDetail(displayId: String, ticketType: Int32) -> Single<ResponseData<WithdrawalRecordDetailData>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/detail/",
      method: .get,
      task: .requestParameters(parameters: [
        "displayId": displayId,
        "ticketType": ticketType
      ], encoding: URLEncoding.default),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<WithdrawalRecordDetailData>.self)
  }

  func getWithdrawalRecords(
    page: String,
    deteBegin: String,
    dateEnd: String,
    status: [String: Int32]) -> Single<ResponseData<[WithdrawalRecordAllData]>>
  {
    var parameters = ["dateRange.begin": deteBegin, "dateRange.end": dateEnd]
    status.forEach { parameters[$0.key] = String($0.value) }
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/logs/\(page)",
      method: .get,
      task: .requestParameters(parameters: parameters, encoding: URLEncoding.default),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<[WithdrawalRecordAllData]>.self)
  }

  func cancelWithdrawal(ticketId: String) -> Completable {
    let request = WithdrawalCancelRequestBeanCodable(ticketId: ticketId)
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/cancel/",
      method: .put,
      task: .requestJSONEncodable(request),
      header: httpClient.headers)
    return httpClient.request(target).asCompletable()
  }

  func sendWithdrawalRequest(withdrawalRequest: WithdrawalBankCardRequestBeanCodable) -> Single<ResponseData<String>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/bank-card",
      method: .post,
      task: .requestJSONEncodable(withdrawalRequest),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<String>.self)
  }

  func getWithdrawalAccount() -> Single<ResponseData<PayloadPage<WithdrawalAccountBean>>> {
    let target = GetAPITarget(service: self.url("api/bank-card"))
    return httpClient.request(target).map(ResponseData<PayloadPage<WithdrawalAccountBean>>.self)
  }

  func sendWithdrawalAddAccount(request: BankCardBeanCodable) -> Single<ResponseData<Nothing>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/bank-card",
      method: .post,
      task: .requestJSONEncodable(request),
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<Nothing>.self)
  }

  func isWithdrawalAccountExist(bankId: Int32, bankName: String, accountNumber: String) -> Single<ResponseData<Bool>> {
    let target = GetAPITarget(service: self.url("api/bank-card/check"))
      .parameters([
        "accountNumber": accountNumber,
        "bankName": bankName,
        "bankId": bankId
      ])
    return httpClient.request(target).map(ResponseData<Bool>.self)
  }

  func deleteWithdrawalAccount(playerBankCardId: String) -> Single<ResponseData<Nothing>> {
    let target = DeleteAPITarget(service: self.url("api/bank-card/\(playerBankCardId)"))
    return httpClient.request(target).map(ResponseData<Nothing>.self)
  }

  func getEachLimit() -> Single<ResponseData<SingleWithdrawalLimitsData>> {
    let target = APITarget(
      baseUrl: httpClient.host,
      path: "api/withdrawal/each-limit",
      method: .get,
      task: .requestPlain,
      header: httpClient.headers)
    return httpClient.request(target).map(ResponseData<SingleWithdrawalLimitsData>.self)
  }

  func getTurnOver() -> Single<ResponseData<TurnoverData>> {
    let target = GetAPITarget(service: self.url("api/withdrawal/turn-over"))
    return httpClient.request(target).map(ResponseData<TurnoverData>.self)
  }

  func getIsAnyTicketApplying() -> Single<NonNullResponseData<Bool>> {
    let target = GetAPITarget(service: self.url("api/withdrawal/is-apply"))
    return httpClient.request(target).map(NonNullResponseData<Bool>.self)
  }

  func isCryptoProcessCertified() -> Single<NonNullResponseData<Bool>> {
    let target = GetAPITarget(service: self.url("api/withdrawal/player-certification/crypto"))
    return httpClient.request(target).map(NonNullResponseData<Bool>.self)
  }
}
