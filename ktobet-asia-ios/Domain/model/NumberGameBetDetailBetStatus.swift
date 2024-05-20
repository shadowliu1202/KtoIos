import Foundation
import sharedbu

extension NumberGameBetDetail.BetStatus {
    var LocalizeString: String {
        switch onEnum(of: self) {
        case .settled(let it):
            switch onEnum(of: it) {
            case .cancelled:
                return Localize.string("common_cancel")
            case .selfCancelled:
                return Localize.string("common_self_canceled")
            case .strikeCancelled:
                return Localize.string("common_strike_canceled")
            case .void:
                return Localize.string("common_void")
            case .winLose(let winLose):
                let amount: AccountCurrency = winLose.winLoss
                let prefix = amount.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
                return prefix + " \(amount.abs().formatString())"
            }
        case .unsettled(let it):
            switch onEnum(of: it) {
            case .confirmed:
                return Localize.string("common_confirm")
            case .pending:
                return Localize.string("common_pending_2")
            }
        }
    }
}
