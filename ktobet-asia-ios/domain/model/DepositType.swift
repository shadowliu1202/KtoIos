import SharedBu

enum SupportPaymentType: Int32 {
    case OfflinePayment = 0
    case UnionScan      = 1
    case WechatScan     = 2
    case AlipayScan     = 3
    case QQScan         = 4
    case Expresspay     = 5
    case OnlineBank     = 6
    case PrepaidCard    = 9
    case UnionH5        = 11
    case Multiple       = 14
    case Crypto         = 2001
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
        case .some(.PrepaidCard):
            self.paymentType = PaymentType.PrepaidCard()
        case .some(.UnionH5):
            self.paymentType = PaymentType.UnionH5()
        case .some(.Multiple):
            self.paymentType = PaymentType.Multiple()
            self.hint = Localize.string("deposit_pay_multiple_hint")
        case .some(.Crypto):
            self.paymentType = PaymentType.Crypto()
            self.hint = Localize.string("deposit_cps_hint")
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
