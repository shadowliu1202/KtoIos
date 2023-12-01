import Foundation
import sharedbu

class ExternalProtocolServiceFactory: ExternalProtocolService {
  private var httpClient: HttpClient!

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getCash() -> CashProtocol {
    CashAdapter(httpClient)
  }

  func getCommon() -> CommonProtocol {
    CommonAdapter(CommonAPI(httpClient))
  }

  func getDeposit() -> DepositProtocol {
    DepositAdapter(DepositAPI(httpClient))
  }

  func getImage() -> ImageProtocol {
    ImageAdapter(ImageApi(httpClient))
  }

  func getNumberGame() -> NumberGameProtocol {
    NumberGameAdapter(NumberGameApi(httpClient))
  }

  func getArcade() -> ArcadeProtocol {
    ArcadeAdapter(ArcadeApi(httpClient))
  }

  func getCrypto() -> CryptoProtocol {
    CryptoAdapter(CryptoAPI(httpClient))
  }

  func getWithdrawal() -> WithdrawalProtocol {
    WithdrawalAdapter(WithdrawalAPI(httpClient))
  }

  func getPlayer() -> PlayerProtocol {
    PlayerAdapter(PlayerApi(httpClient))
  }

  func getCustomerService() -> CustomerServiceProtocol {
    CSAdapter(httpClient)
  }

  func getSurveyService() -> CSSurveyProtocol {
    CSSurveyAdapter(httpClient)
  }
}
