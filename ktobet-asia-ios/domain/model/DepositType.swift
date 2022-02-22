import SharedBu

protocol DepositSelection {
    var id: String { get set }
    var name: String { get set }
    var isRecommend: Bool { get set }
    var hint: String { get set }
}

extension DepositSelection {
    var hint: String { get { "" } set { } }
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
    
    init(_ online: PaymentsDTO.Online) {
        self.hint = online.hint
        self.id = online.identity
        self.name = online.name
        self.isRecommend = online.isRecommend
    }
}
