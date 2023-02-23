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
      return UIColor.redF20000
    case .onhold:
      return UIColor.orangeFF8000
    case .verified:
      return UIColor.green6AB336
    case .pending,
         .unknown:
      return UIColor.gray9B9B9B
    default:
      return UIColor.gray9B9B9B
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
