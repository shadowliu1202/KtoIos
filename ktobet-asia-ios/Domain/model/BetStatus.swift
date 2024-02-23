import sharedbu

extension BetStatus_ {
  static func convert(_ type: Int32) -> BetStatus_ {
    switch type {
    case 0: return .pending
    case 1: return .reject
    case 2: return .confirmed
    case 3: return .void
    case 4: return .canceled
    case 5: return .settled
    default: return .pending
    }
  }
}
