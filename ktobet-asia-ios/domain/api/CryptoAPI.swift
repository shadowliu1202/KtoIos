import Foundation
import RxSwift
import SharedBu

class CryptoAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func deleteBankCards(_ bankCardId: [String: String]) -> Completable {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-bank-card",
          method: .delete,
          task: .requestParameters(parameters: bankCardId)))
      .asCompletable()
  }

  func getCryptoBankCard() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-bank-card",
          method: .get))
  }

  func getCryptoExchangeRate(_ cryptoCurrencyID: Int32) -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-currency-rate/\(cryptoCurrencyID)",
          method: .get))
  }

  func getCryptoLimitations() -> Single<String> {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/withdrawal/each-crypto-limit",
          method: .get))
  }

  func createCryptoBankCard(request: CryptoBankCardRequest) -> Single<String> {
    let codable = CryptoBankCardRequestCodable(
      cryptoCurrency: request.cryptoCurrency,
      cryptoWalletName: request.cryptoWalletName,
      cryptoWalletAddress: request.cryptoWalletAddress,
      cryptoNetwork: request.cryptoNetwork)

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-bank-card",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func resendOTP(_ accountType: Int32) -> Completable {
    httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-bank-card/resend-otp/\(accountType)",
          method: .post))
      .asCompletable()
  }

  func sendAccountVerifyOTP(request: AccountVerifyRequest) -> Single<String> {
    let codable = AccountVerifyRequestCodable(
      playerCryptoBankCardId: request.playerCryptoBankCardId,
      accountType: Int(request.accountType))

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-bank-card/send-otp",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }

  func verifyOTP(request: OTPVerifyRequest) -> Single<String> {
    let codable = OTPVerifyRequestCodable(
      verifyCode: request.verifyCode,
      accountType: Int(request.accountType))

    return httpClient
      .requestJsonString(
        NewAPITarget(
          path: "api/crypto-bank-card/verify-otp",
          method: .post,
          task: .requestJSONEncodable(codable)))
  }
}
