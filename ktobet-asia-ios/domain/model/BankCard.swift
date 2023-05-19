import SharedBu
import UIKit

extension BankCard {
  func createBankCardStatus(_ index: Int) -> BankCardStatus {
    switch index {
    case 0:
      return .none
    case 1,
         2:
      return .default_
    default:
      return .none
    }
  }

  var verifyStatusColor: UIColor {
    switch self.verifyStatus {
    case .void_:
      return UIColor.primaryDefault
    case .onhold:
      return UIColor.alert
    case .verified:
      return UIColor.statusSuccess
    case .pending,
         .unknown:
      return UIColor.textPrimary
    default:
      return UIColor.textPrimary
    }
  }

  var verifyStatusLocalize: String {
    switch self.verifyStatus {
    case .void_:
      return Localize.string("withdrawal_bankcard_fail")
    case .onhold:
      return Localize.string("withdrawal_bankcard_locked")
    case .verified:
      return Localize.string("withdrawal_bankcard_verified")
    case .pending:
      return Localize.string("withdrawal_bankcard_new")
    default:
      return ""
    }
  }
}
