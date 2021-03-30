import UIKit
import share_bu

extension WithdrawalAccount {
    var verifyStatusColor: UIColor {
        get {
            switch self.verifyStatus {
            case .infoincorrect:
                return UIColor.redForDarkFull
            case .verifying:
                return UIColor.orangeFull
            case .verified:
                return UIColor.textSuccessedGreen
            case .unknown, .unverified:
                return UIColor.textPrimaryDustyGray
            default:
                return UIColor.textPrimaryDustyGray
            }
        }
    }
    var verifyStatusLocalize: String {
        get {
            switch self.verifyStatus {
            case .infoincorrect:
                return Localize.string("withdrawal_bankcard_fail")
            case .verifying:
                return Localize.string("withdrawal_bankcard_locked")
            case .verified:
                return Localize.string("withdrawal_bankcard_verified")
            case .unverified:
                return Localize.string("withdrawal_bankcard_new")
            default:
                return ""
            }
        }
    }
}
