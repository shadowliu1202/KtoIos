import SharedBu

enum SupportPaymentType: Int32 {
    case OfflinePayment = 0
    case UnionScan      = 1
    case WechatScan     = 2
    case AlipayScan     = 3
    case QQScan         = 4
    case Expresspay     = 5
    case OnlineBank     = 6
    case FY             = 7
    case Weipay         = 8
    case PrepaidCard    = 9
    case YF             = 10
    case UnionH5        = 11
    case JPay           = 12
    case AsiaPay        = 13
    case Multiple       = 14
    case JeePay         = 15
    case Wlxx           = 16
    case Ethereum       = 2001
}
class DepositType {
    var supportType: SupportPaymentType?
    var paymentType: PaymentType
    var method: DepositMethod
    var hint: String?
    
    init(id: Int32, name: String, min: CashAmount, max: CashAmount, isFavorite: Bool) {
        supportType = SupportPaymentType(rawValue: id)
        switch supportType {
        case .some(.OfflinePayment):
            self.paymentType = PaymentType.OfflinePayment()
        case .some(.UnionScan):
            self.paymentType = PaymentType.UnionScan()
        case .some(.WechatScan):
            self.paymentType = PaymentType.WechatScan()
        case .some(.AlipayScan):
            self.paymentType = PaymentType.AlipayScan()
        case .some(.QQScan):
            self.paymentType = PaymentType.QQScan()
        case .some(.Expresspay):
            self.paymentType = PaymentType.Expresspay()
        case .some(.OnlineBank):
            self.paymentType = PaymentType.OnlineBank()
        case .some(.FY):
            self.paymentType = PaymentType.FY()
        case .some(.Weipay):
            self.paymentType = PaymentType.Weipay()
        case .some(.YF):
            self.paymentType = PaymentType.YF()
        case .some(.JPay):
            self.paymentType = PaymentType.JPay()
        case .some(.AsiaPay):
            self.paymentType = PaymentType.AsiaPay()
        case .some(.JeePay):
            self.paymentType = PaymentType.JeePay()
        case .some(.Wlxx):
            self.paymentType = PaymentType.Wlxx()
        case .some(.PrepaidCard):
            self.paymentType = PaymentType.PrepaidCard()
        case .some(.UnionH5):
            self.paymentType = PaymentType.UnionH5()
        case .some(.Multiple):
            self.paymentType = PaymentType.Multiple()
            self.hint = Localize.string("deposit_pay_multiple_hint")
        case .some(.Ethereum):
            self.paymentType = PaymentType.Ethereum()
        case .none:
            self.paymentType = PaymentType.OfflinePayment()
        }
        switch supportType {
        case .some(.OfflinePayment):
            self.method = self.paymentType.createMethod(name: Localize.string("deposit_offline_step1_title"), limitation: AmountRange(min: min, max: max), isFavorite: isFavorite)
        default:
            self.method = self.paymentType.createMethod(name: name, limitation: AmountRange(min: min, max: max), isFavorite: isFavorite)
        }
    }
}
