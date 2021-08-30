import Foundation
import SharedBu

extension NumberGameBetDetail.BetStatus {
    var LocalizeString: String {
        switch self {
        case is NumberGameBetDetail.BetStatusUnsettledPending:
            return Localize.string("common_pending_2")
        case is NumberGameBetDetail.BetStatusUnsettledConfirmed:
            return Localize.string("common_confirm")
        case is NumberGameBetDetail.BetStatusSettledWinLose:
            let amount: CashAmount = (self as! NumberGameBetDetail.BetStatusSettledWinLose).winLoss
            let prefix = amount.isPositive() ? Localize.string("common_win") : Localize.string("common_lose")
            return prefix + " \(amount.absoluteValue().description())"
        case is NumberGameBetDetail.BetStatusSettledVoid:
            return Localize.string("common_void")
        case is NumberGameBetDetail.BetStatusSettledSelfCancelled:
            return Localize.string("common_self_canceled")
        case is NumberGameBetDetail.BetStatusSettledCancelled:
            return Localize.string("common_cancel")
        case is NumberGameBetDetail.BetStatusSettledStrikeCancelled:
            return Localize.string("common_strike_canceled")
        default:
            return ""
        }
    }
}
