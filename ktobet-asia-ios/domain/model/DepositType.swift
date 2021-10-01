import SharedBu

enum SupportDepositType: Int32 {
    case UnionScan      = 1
    case WechatScan     = 2
    case AlipayScan     = 3
    case QQScan         = 4
    case WanHui         = 5
    case FengYun        = 6
    case PrepaidCard    = 9
    case UnionH5        = 11
    case Multiple       = 14
    case Ethereum       = 2001
}

class DepositTypeFactory {
    class func create(id: Int32, name: String, min: CashAmount, max: CashAmount, isFavorite: Bool) -> DepositRequest.DepositType {
        if id == 0 {
            return DepositRequest.DepositTypeOffline(id: id, name: name, min: min, max: max, isFavorite: isFavorite)
        } else if let support = SupportDepositType(rawValue: id) {
            switch support {
                //1...3, 5, 6, 11:
            case .UnionScan, .WechatScan, .AlipayScan, .WanHui, .FengYun, .UnionH5:
                return DepositRequest.DepositTypeThirdParty(id: id, name: name, min: min, max: max, isFavorite: isFavorite, hasRedirection: false, hint: "")
            case .Multiple:
                return DepositRequest.DepositTypeThirdParty(id: id, name: name, min: min, max: max, isFavorite: isFavorite, hasRedirection: false, hint: Localize.string("deposit_pay_multiple_hint"))
            case .Ethereum:
                return DepositRequest.DepositTypeCrypto(id: id, name: name, min: min, max: max, isFavorite: isFavorite)
            default:
                return DepositRequest.DepositTypeUnknown()
            }
        }
        return DepositRequest.DepositTypeUnknown()
    }
}
