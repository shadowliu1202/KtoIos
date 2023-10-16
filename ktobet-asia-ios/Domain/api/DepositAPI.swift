import Foundation
import RxSwift
import sharedbu

class DepositAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getCryptoCurrency() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/crypto-currency",
          method: .get))
  }

  func getExchangeFeeSetting(cryptoMarket: Int32) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/crypto-exchange/\(cryptoMarket)/fee-setting",
          method: .get))
  }

  func getDepositRecordDetail(id: String) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/detail",
          method: .get,
          task: .requestParameters(
            parameters: ["displayId": id])))
  }

  func getDepositLogs() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit",
          method: .get))
  }

  func getDepositRecords(
    page: Int32 = 1,
    begin: String,
    end: String,
    status: [String: String]) -> Single<String>
  {
    var parameters = status
    parameters["dateRange.begin"] = begin
    parameters["dateRange.end"] = end

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/logs/\(page)",
          method: .get,
          task: .requestParameters(
            parameters: parameters)))
  }

  func getDepositMethods(depositType: Int32) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/player-deposit-method/",
          method: .get,
          task: .requestParameters(
            parameters: ["depositType": depositType])))
  }

  func getDepositOfflineBankAccounts() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/bank",
          method: .get))
  }

  func getDepositTypesString() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/player-deposit-type",
          method: .get))
  }

  func getUpdateOnlineDepositCrypto(displayId: String) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/update-online-deposit-crypto",
          method: .get,
          task: .requestParameters(
            parameters: ["displayId": displayId])))
  }

  func onlineDepositCrypto(bean: CryptoDepositRequestBean) -> Single<String> {
    let codable = CryptoDepositRequestBeanCodable(cryptoCurrency: bean.cryptoCurrency)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/online-deposit-crypto",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func bindingImageWithDepositRecord(id: String, bean: ImageMappingRequestBean) -> Single<String> {
    let codable = WithdrawalImagesCodable(
      ticketStatus: bean.ticketStatus,
      images: bean.images
        .map { imageBean in
          ImageBeanCodable(
            imageID: imageBean.imageId,
            fileName: imageBean.fileName)
        })

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/images/\(id)",
          method: .put,
          task: .requestJSONEncodable(codable)))
  }

  func sendOfflineDepositRequest(request: DepositOfflineRequestBean) -> Single<String> {
    let codable = DepositOfflineRequestBeanCodable(
      paymentTokenID: request.paymentTokenId,
      requestAmount: request.requestAmount,
      remitterAccountNumber: request.remitterAccountNumber,
      remitter: request.remitter,
      remitterBankName: request.remitterBankName,
      channel: request.channel,
      depositType: request.depositType)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/offline",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func sendOnlineDepositRequest(request: OnlineDepositRequestBean) -> Single<String> {
    let codable = OnlineDepositRequestBeanCodable(
      paymentTokenID: request.paymentTokenId,
      requestAmount: request.requestAmount,
      remitter: request.remitter,
      channel: request.channel,
      remitterAccountNumber: request.remitterAccountNumber,
      remitterBankName: request.remitterBankName,
      depositType: request.depositType,
      providerId: request.providerId,
      bankCode: request.bankCode)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/deposit/online-deposit",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }
}
