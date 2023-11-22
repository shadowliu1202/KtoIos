import Foundation
import sharedbu

protocol OnlinePaymentViewModelProtocol {
  var remitMethodName: String { get }
  var gateways: [OnlinePaymentDataModel.Gateway] { get }

  var remitterName: String { get }

  var remitInfoErrorMessage: OnlinePaymentDataModel.RemittanceInfoError { get }
  var submitButtonDisable: Bool { get }

  func setupData(onlineDTO: PaymentsDTO.Online)
  func verifyRemitInfo(info: OnlinePaymentDataModel.RemittanceInfo)
  func submitRemittance(
    info: OnlinePaymentDataModel.RemittanceInfo,
    remitButtonOnSuccess: @escaping (_ url: String) -> Void)
  func getSupportLocale() -> SupportLocale
}

struct OnlinePaymentDataModel {
  struct Gateway: Equatable, Identifiable {
    let id: String
    let name: String
    let hint: String
    let remitType: PaymentsDTO.RemitType
    let remitBanks: [String]
    let cashType: Self.CashType
    let isAccountNumberDenied: Bool
    let isInstructionDisplayed: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.id == rhs.id
    }

    enum CashType {
      case input(limitation: (min: String, max: String), isFloatAllowed: Bool)
      case option(amountList: [String])
    }
  }

  struct RemittanceInfo {
    let selectedGatewayID: String?
    let supportBankName: String?
    let remitterName: String?
    let remitterAccountNumber: String?
    let remitAmount: String?

    init(
      _ selectedGatewayID: String?,
      _ supportBankName: String?,
      _ remitterName: String?,
      _ remitterAccountNumber: String?,
      _ remitAmount: String?)
    {
      self.selectedGatewayID = selectedGatewayID
      self.supportBankName = supportBankName
      self.remitterName = remitterName
      self.remitterAccountNumber = remitterAccountNumber
      self.remitAmount = remitAmount
    }
  }

  struct RemittanceInfoError: Equatable {
    let remitterName: String
    let remitterAccountNumber: String
    let remitAmount: String

    static let empty = Self(
      remitterName: "",
      remitterAccountNumber: "",
      remitAmount: "")

    var isEmpty: Bool {
      self == Self.empty
    }
  }
}
