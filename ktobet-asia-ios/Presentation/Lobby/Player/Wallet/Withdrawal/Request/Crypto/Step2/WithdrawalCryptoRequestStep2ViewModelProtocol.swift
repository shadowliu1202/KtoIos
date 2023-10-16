import Foundation
import RxSwift
import sharedbu

protocol WithdrawalCryptoRequestStep2ViewModelProtocol: AnyObject {
  var requestInfo: [DefaultRow.Common] { get }
  var afterInfo: [DefaultRow.Common] { get }
  var submitDisable: Bool { get }

  func setup(model: WithdrawalCryptoRequestConfirmDataModel.SetupModel?)
  func requestCryptoWithdrawalTo(_ onCompleted: @escaping () -> Void)
  func getSupportLocale() -> SupportLocale
}

struct WithdrawalCryptoRequestConfirmDataModel {
  struct SetupModel {
    let cryptoWallet: WithdrawalDto.CryptoWallet
    let cryptoAmount: String
    let cryptoSimpleName: String
    let fiatAmount: String
    let fiatSimpleName: String
    let ratio: String
  }

  struct ConfirmInfo {
    let cryptoCurrency: String
    let networkAddress: String
    let fiatCurrency: String
    let ratio: String
    let dailyCount: String
    let dailyAmount: String
    let remainingRequirement: String
    let request: ConfirmRequest
  }

  struct ConfirmRequest {
    let walletId: String
    let fiatAmount: String
    let exchangedCryptoAmount: String
  }
}
