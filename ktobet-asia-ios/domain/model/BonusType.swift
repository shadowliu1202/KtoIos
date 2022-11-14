import SharedBu

extension BonusType {
    class func convert(_ type: Int32) -> BonusType {
        return BonusType.convertToBonusType(type).1
    }
    
    class func convert(_ type: BonusType) -> Int32 {
        return BonusType.convertToBonusType(type).0
    }
    
    private class func convertToBonusType(_ type: Any) -> (Int32, BonusType) {
        switch type {
        case let b as BonusType:
            switch b {
            case .freebet:          return (1, BonusType.freebet)
            case .depositbonus:     return (2, BonusType.depositbonus)
            case .product:          return (3, BonusType.product)
            case .rebate:           return (4, BonusType.rebate)
            case .levelbonus:       return (5, BonusType.levelbonus)
            case .vvipcashback:     return (7, BonusType.vvipcashback)
            default:                return (-1, BonusType.other)
            }
        case let i as Int32:
            switch i {
            case 1:             return (1, BonusType.freebet)
            case 2:             return (2, BonusType.depositbonus)
            case 3:             return (3, BonusType.product)
            case 4:             return (4, BonusType.rebate)
            case 5:             return (5, BonusType.levelbonus)
            case 7:             return (7, BonusType.vvipcashback)
            default:            return (-1, BonusType.other)
            }
        default:                return (-1, BonusType.other)
        }
    }
}
