import SharedBu

extension BetStatus_ {
    class func convert(_ type: Int32) -> BetStatus_ {
        return BetStatus_.convertToBetStatus(type).1
    }
    
    class func convert(_ type: BetStatus) -> Int32 {
        return BetStatus_.convertToBetStatus(type).0
    }
    
    private class func convertToBetStatus(_ type: Any) -> (Int32, BetStatus_) {
        switch type {
        case let b as BetStatus_:
            switch b {
            case .pending:          return (0, .pending)
            case .reject:           return (1, .reject)
            case .confirmed:        return (2, .confirmed)
            case .void_:            return (3, .void_)
            case .canceled:         return (3, .canceled)
            case .settled:          return (3, .settled)
            default:                return (0, BetStatus_.pending)
            }
        case let i as Int32:
            switch i {
            case 0:             return (0, .pending)
            case 1:             return (1, .reject)
            case 2:             return (2, .confirmed)
            case 3:             return (3, .void_)
            case 4:             return (3, .canceled)
            case 5:             return (3, .settled)
            default:            return (0, BetStatus_.pending)
            }
        default:                return (0, BetStatus_.pending)
        }
    }
}
