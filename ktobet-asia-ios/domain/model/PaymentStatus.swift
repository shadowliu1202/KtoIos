import UIKit
import SharedBu

extension PaymentStatus {
    func toLogString() -> String {
        switch self {
        case .pending:
            return Localize.string("common_pending")
        case .floating:
            return Localize.string("common_floating")
        case .approved:
            return Localize.string("common_approved")
        case .cancel:
            return Localize.string("common_cancel")
        case .fail:
            return Localize.string("common_reject")
        default:
            return ""
        }
    }
    
    func toLogColor() -> UIColor {
        switch self {
        case .floating:
            return UIColor.orangeFull
        default:
            return UIColor.textPrimaryDustyGray
        }
    }
}
