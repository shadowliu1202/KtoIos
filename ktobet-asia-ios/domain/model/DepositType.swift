import SharedBu

enum DepositType: Int {
    case OfflinePayment = 0
    case UnionScan = 1
    case WechatScan = 2
    case AlipayScan = 3
    case QQScan = 4
    case Expresspay = 5
    case OnlineBank = 6
    case PrepaidCard = 9
    case UnionH5 = 11
    case Multiple = 14
    case CryptoMarket = 22
    case JinYiDigital = 24
    case QQPay = 25
    case Crypto = 2001
    
    func imageName(locale: SupportLocale)  -> String {
        let name = "icon.deposit." + "\(rawValue)"
        
        if self == .OfflinePayment,
           locale is SupportLocale.Vietnam {
            return name + "-VN"
        }
        else {
            return name
        }
    }
}

protocol DepositSelection {
    var id: String { get set }
    var name: String { get set }
    var isRecommend: Bool { get set }
    var hint: String { get set }
}

extension DepositSelection {
    var hint: String { get { "" } set { } }
    
    var type: DepositType? {
        guard let id = Int(id),
              let type = DepositType(rawValue: id)
        else { return nil }
        
        return type
    }
}

struct OfflinePayment: DepositSelection {
    var id: String
    var name: String
    var isRecommend: Bool
    
    init(_ offline: PaymentsDTO.Offline) {
        self.id = offline.identity
        self.name = Localize.string("deposit_offline_step1_title")
        self.isRecommend = offline.isRecommend
    }
}

struct CryptoPayment: DepositSelection {
    var hint: String
    var id: String
    var name: String
    var isRecommend: Bool
    
    init(_ crypto: PaymentsDTO.Crypto) {
        self.hint = crypto.hint
        self.id = crypto.identity
        self.name = crypto.name
        self.isRecommend = crypto.isRecommend
    }
}

struct OnlinePayment: DepositSelection {
    var hint: String
    var id: String
    var name: String
    var isRecommend: Bool
    var paymentDTO: PaymentsDTO.Online
    
    init(_ online: PaymentsDTO.Online) {
        self.hint = online.hint
        self.id = online.identity
        self.name = online.name
        self.isRecommend = online.isRecommend
        self.paymentDTO = online
    }
}

struct CryptoMarket: DepositSelection {
    var id: String
    var name: String
    var hint: String
    var isRecommend: Bool
    
    init(_ cryptoMarket: PaymentsDTO.CryptoMarket) {
        self.id = cryptoMarket.identity
        self.name = cryptoMarket.name
        self.hint = cryptoMarket.hint
        self.isRecommend = cryptoMarket.isRecommend
    }
}
