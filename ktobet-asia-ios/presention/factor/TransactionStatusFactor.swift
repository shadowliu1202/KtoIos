import Foundation
import share_bu

class TransactionStatusFactor {
    class func title(_ status: TransactionStatus) -> String {
        switch status {
        case .floating:
            return Localize.string("common_floating_2")
        case .pending:
            return Localize.string("common_pending")
        case .reject:
            return Localize.string("common_reject")
        case .approved:
            return Localize.string("common_success")
        case .cancel:
            return Localize.string("common_cancel")
        default:
            return ""
        }
    }
}
