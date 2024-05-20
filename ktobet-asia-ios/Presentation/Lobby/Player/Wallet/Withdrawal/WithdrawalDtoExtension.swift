import sharedbu
import UIKit

extension WithdrawalDto.Log {
  func toStatusText() -> String {
    switch status {
    case .pending: return if isBankProcessing { Localize.string("common_pending_hold") } else { Localize.string("common_pending") }
    case .floating: return Localize.string("common_floating")
    case .approved: return Localize.string("common_approved")
    case .cancel: return Localize.string("common_cancel")
    case .fail: return Localize.string("common_reject")
    case .other: return ""
    }
  }
  
  func toStatusColor() -> UIColor {
    switch status {
    case .floating:
      return UIColor.alert
    case .approved,
         .cancel,
         .fail,
         .other,
         .pending:
      return UIColor.textPrimary
    }
  }
}
