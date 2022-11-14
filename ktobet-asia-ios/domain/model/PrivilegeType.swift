import SharedBu

extension PrivilegeType {
    class func convert(_ type: Int32) -> PrivilegeType {
        return PrivilegeType.convertToPrivilegeType(type).1
    }
    
    class func convert(_ type: PrivilegeType) -> Int32 {
        return PrivilegeType.convertToPrivilegeType(type).0
    }
    
    private class func convertToPrivilegeType(_ type: Any) -> (Int32, PrivilegeType) {
        switch type {
        case let p as PrivilegeType:
            switch p {
            case .none:             return (0, PrivilegeType.none)
            case .freebet:          return (1, PrivilegeType.freebet)
            case .depositbonus:     return (2, PrivilegeType.depositbonus)
            case .product:          return (3, PrivilegeType.product)
            case .rebate:           return (4, PrivilegeType.rebate)
            case .levelbonus:       return (5, PrivilegeType.levelbonus)
            case .vvipcashback:     return (7, PrivilegeType.vvipcashback)
            case .feedback:         return (90, PrivilegeType.feedback)
            case .withdrawal:       return (91, PrivilegeType.withdrawal)
            case .domain:           return (92, PrivilegeType.domain)
            default:                return (0, PrivilegeType.none)
            }
        case let i as Int32:
            switch i {
            case 1:             return (1, PrivilegeType.freebet)
            case 2:             return (2, PrivilegeType.depositbonus)
            case 3:             return (3, PrivilegeType.product)
            case 4:             return (4, PrivilegeType.rebate)
            case 5:             return (5, PrivilegeType.levelbonus)
            case 7:             return (7, PrivilegeType.vvipcashback)
            case 90:            return (90, PrivilegeType.feedback)
            case 91:            return (91, PrivilegeType.withdrawal)
            case 92:            return (92, PrivilegeType.domain)
            default:            return (0, PrivilegeType.none)
            }
        default:                return (0, PrivilegeType.none)
        }
    }
}
