import UIKit
import SharedBu

extension WithdrawalAccount {
    var verifyStatusColor: UIColor {
        get {
            switch self.verifyStatus {
            case .void_:
                return UIColor.redForDarkFull
            case .onhold:
                return UIColor.orangeFull
            case .verified:
                return UIColor.textSuccessedGreen
            case .unknown, .pending:
                return UIColor.textPrimaryDustyGray
            default:
                return UIColor.textPrimaryDustyGray
            }
        }
    }
    var verifyStatusLocalize: String {
        get {
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
}
