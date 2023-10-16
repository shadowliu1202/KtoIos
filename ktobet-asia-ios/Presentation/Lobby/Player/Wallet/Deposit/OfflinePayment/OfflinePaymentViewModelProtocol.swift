import Foundation
import sharedbu

protocol OfflinePaymentViewModelProtocol {
  var gateways: [OfflinePaymentDataModel.Gateway] { get }
  var remitBankList: [String] { get }
  var remitterName: String { get }
  var remitAmountLimitRange: String { get }
  var remitInfoErrorMessage: OfflinePaymentDataModel.RemittanceInfoError { get }

  var submitButtonDisable: Bool { get }

  func fetchGatewayData()
  func getRemitterName()

  func verifyRemitInfo(info: OfflinePaymentDataModel.RemittanceInfo)
  func submitRemittance(gatewayId: String?, onClick: @escaping (OfflineDepositDTO.Memo, PaymentsDTO.BankCard) -> Void)
}

struct OfflinePaymentDataModel {
  struct Gateway: Equatable {
    let id: String
    let name: String
    let iconName: String
  }

  struct RemittanceInfo {
    let selectedGatewayId: String?
    let bankName: String?
    let remitterName: String?
    let bankCardNumber: String?
    let amount: String?
  }

  struct RemittanceInfoError: Equatable {
    let bankName: String
    let remitterName: String
    let bankCardNumber: String
    let amount: String

    var isEmpty: Bool {
      self == Self(
        bankName: "",
        remitterName: "",
        bankCardNumber: "",
        amount: "")
    }
  }
}
