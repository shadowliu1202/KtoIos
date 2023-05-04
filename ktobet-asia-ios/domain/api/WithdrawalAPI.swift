import Foundation
import RxSwift
import SharedBu

class WithdrawalAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func deleteWithdrawalAccount(playerBankCardId: String) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/bank-card/\(playerBankCardId)",
          method: .delete))
  }

  func isWithdrawalAccountExist(bankId: Int32, bankName: String, accountNumber: String) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/bank-card/check",
          method: .get,
          task: .requestParameters(
            parameters: [
              "accountNumber": accountNumber,
              "bankName": bankName,
              "bankId": bankId
            ])))
  }

  func isCryptoProcessCertified() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/player-certification/crypto",
          method: .get))
  }

  func getBankCard() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/bank-card",
          method: .get))
  }

  func getWithdrawalCryptoTransactionSuccessLog() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/crypto-transaction-success-log",
          method: .get))
  }

  func getWithdrawalDetail(displayId: String) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/detail/",
          method: .get,
          task: .requestParameters(
            parameters: [
              "displayId": displayId,
            ])))
  }

  func getWithdrawalEachLimit() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/each-limit",
          method: .get))
  }

  func getIsAnyTicketApplying() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/is-apply",
          method: .get))
  }

  func getWithdrawalLimitCount() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/limit-count",
          method: .get))
  }

  func getWithdrawalLogs(
    page: Int = 1,
    dateRangeBegin: String,
    dateRangeEnd: String,
    statusDictionary: [String: String]) -> Single<String>
  {
    var parameters = statusDictionary
    parameters["dateRange.begin"] = dateRangeBegin
    parameters["dateRange.end"] = dateRangeEnd

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/logs/\(page)",
          method: .get,
          task: .requestParameters(parameters: parameters)))
  }

  func getWithdrawalTurnOverRef() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/turn-over",
          method: .get))
  }

  func getWithdrawals() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal",
          method: .get))
  }

  func postBankCard(bean: BankCardBean) -> Single<String> {
    let codable = BankCardBeanCodable(
      bankID: bean.bankId,
      bankName: bean.bankName,
      branch: bean.branch,
      accountName: bean.accountName,
      accountNumber: bean.accountNumber,
      address: bean.address,
      city: bean.city,
      location: bean.location)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/bank-card",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func postWithdrawalToBankCard(bean: WithdrawalBankCardRequestBean) -> Single<String> {
    let codable = WithdrawalBankCardRequestBeanCodable(
      requestAmount: bean.requestAmount.toAccountCurrency().bigAmount.doubleValue(exactRequired: false),
      playerBankCardId: bean.playerBankCardId)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/bank-card",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func createCryptoWithdrawal(request: CryptoWithdrawalRequest) -> Single<String> {
    let codable = CryptoWithdrawalRequestCodable(
      playerCryptoBankCardId: request.playerCryptoBankCardId,
      requestCryptoAmount: request.requestCryptoAmount,
      requestFiatAmount: request.requestFiatAmount,
      cryptoCurrency: request.cryptoCurrency)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/crypto",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func putWithdrawalCancel(bean: WithdrawalCancelBean) -> Single<String> {
    let codable = WithdrawalCancelRequestBeanCodable(ticketId: bean.ticketId)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/cancel/",
          method: .put,
          task: .requestJSONEncodable(codable)))
  }

  func putWithdrawalImages(id: String, bean: WithdrawalImages) -> Single<String> {
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
          path: "api/withdrawal/images/\(id)",
          method: .put,
          task: .requestJSONEncodable(codable)))
  }
}
