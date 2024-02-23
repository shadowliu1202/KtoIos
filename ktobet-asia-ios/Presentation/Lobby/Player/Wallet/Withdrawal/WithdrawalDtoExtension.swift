import sharedbu
import UIKit

extension WithdrawalDto.LogStatus {
  func toString() -> String {
    switch self {
    case .pending: return Localize.string("common_pending")
    case .pendingHold: return Localize.string("common_pending_hold")
    case .floating: return Localize.string("common_floating")
    case .approved: return Localize.string("common_approved")
    case .cancel: return Localize.string("common_cancel")
    case .fail: return Localize.string("common_reject")
    case .other: return ""
    }
  }
  
  func toColor() -> UIColor {
    switch self {
    case .floating:
      return UIColor.alert
    case .approved,
         .cancel,
         .fail,
         .other,
         .pending,
         .pendingHold:
      return UIColor.textPrimary
    }
  }
}
