import Foundation
import SharedBu

class StringMapper {
    static let sharedInstance = StringMapper()
    private init() { }
    
    func parse(_ transactionStatus: TransactionStatus, isPendingHold: Bool, ignorePendingHold: Bool) -> String {
        switch transactionStatus {
        case .approved:
            return Localize.string("common_approved")
        case .cancel:
            return Localize.string("common_cancel")
        case .floating:
            return Localize.string("common_floating")
        case .void_, .reject:
            return Localize.string("common_reject")
        case .pending:
            if isPendingHold {
                return ignorePendingHold ? Localize.string("common_pending") : Localize.string("common_pending_hold")
            } else {
                return Localize.string("common_pending")
            }
        default:
            return ""
        }
    }
}
