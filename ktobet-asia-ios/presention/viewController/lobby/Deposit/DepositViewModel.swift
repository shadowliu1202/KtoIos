import Foundation
import RxSwift
import SharedBu
import RxCocoa

enum WeiLaiProvidAmount: String {
    case fifty          = "50"
    case oneHundred     = "100"
    case twoHundred     = "200"
}
class DepositViewModel {
    static let imageMBSizeLimit = 20
    static let selectedImageCountLimit = 3
    private var depositUseCase: DepositUseCase!
    private var playerUseCase: PlayerDataUseCase!
    private var bankUseCase: BankUseCase!
    var accountPatternGenerator: AccountPatternGenerator!
    var filterBanks = BehaviorRelay<[SimpleBank]>(value: [SimpleBank]())
    private let disposeBag = DisposeBag()
    var dateBegin: Date?
    var dateEnd: Date?
    var status: [TransactionStatus] = []
    var relayBankName = BehaviorRelay<String>(value: "")
    var relayBankId = BehaviorRelay<Int32>(value: 0)
    var relayName = BehaviorRelay<String>(value: "")
    var relayBankNumber = BehaviorRelay<String>(value: "")
    var relayBankAmount = BehaviorRelay<String>(value: "")
    var dropdownAmount = BehaviorRelay<String>(value: WeiLaiProvidAmount.fifty.rawValue)
    var Allbanks: [SimpleBank] = []
    var uploadImageDetail: [Int: UploadImageDetail] = [:]
    var selectedReceiveBank: OfflineBank!
    var selectedGateway: PaymentGateway! {
        didSet {
            self.subjectGateway.onNext(selectedGateway)
            self.paymentSlip.accept(selectedGateway.createSlip(method: self.selectedType.method))
        }
    }
    private var subjectGateway = PublishSubject<PaymentGateway>()
    private(set) lazy var paymentSlip = BehaviorRelay<PaymentSlip?>(value: nil)
    var minAmountLimit: Double = 0
    var maxAmountLimit: Double = 0
    var pagination: Pagination<DepositRecord>!
    var selectedType: DepositType!
    let imgIcon: [Int32: String] = [0: Localize.string("Topup ¥(32)"),
                                    1: "UnionPay(32)",
                                    2: "WeChatPay(32)",
                                    3: "AliPay(32)",
                                    5: "秒存(32)",
                                    6: "閃充(32)",
                                    11: "雲閃付(32)",
                                    14: "iconPayMultiple",
                                    2001: "Crypto"]
    init(depositUseCase: DepositUseCase, playerUseCase: PlayerDataUseCase, bankUseCase: BankUseCase, accountPatternGenerator: AccountPatternGenerator) {
        self.depositUseCase = depositUseCase
        self.playerUseCase = playerUseCase
        self.bankUseCase = bankUseCase
        self.accountPatternGenerator = accountPatternGenerator
        
        self.relayName.accept(" ")
        getPlayerRealName().asObservable().bind(to: self.relayName).disposed(by: disposeBag)
        
        pagination = Pagination<DepositRecord>(callBack: {(page) -> Observable<[DepositRecord]> in
            self.getDepositRecords(page: String(page))
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError({ error -> Observable<[DepositRecord]> in
                    Observable.empty()
                })
        })
    }
    
    func getPlayerRealName() -> Single<String> {
        playerUseCase.getPlayerRealName()
    }
    
    func getDepositType() -> Single<[DepositType]> {
        return depositUseCase.getDepositTypes()
    }
    
    func getDepositRecord() -> Single<[DepositRecord]> {
        return depositUseCase.getDepositRecords()
    }
    
    func getDepositTypeImage(depositTypeId: Int32) -> String {
        return imgIcon[depositTypeId] ?? "Default(32)"
    }
    
    func getBanks() -> Single<[(Int, Bank)]> {
        return bankUseCase.getBankMap()
    }
    
    func getDepositTakingCryptos() -> Single<[TakingCrypto]> {
        depositUseCase.getDepositTakingCryptos()
    }
    
    func getDepositOfflineBankAccounts() -> Single<[OfflineBank]> {
        return depositUseCase.getDepositOfflineBankAccounts().map { $0.sorted { (b1, b2) -> Bool in
            b1.shortName < b2.shortName
        } }
    }
    
    func depositOffline(depositRequest: DepositRequest_, depositTypeId: Int32) -> Single<String> {
        return depositUseCase.depositOffline(depositRequest: depositRequest, depositTypeId: depositTypeId)
    }
    
    func depositOnline(depositTypeId: Int32) -> Single<String> {
        let accountNum = needCashOption(gateway: selectedGateway) ? dropdownAmount.value : relayBankAmount.value
        if let paymentSlip = paymentSlip.value {
            let remitter = DepositRequest_.Remitter(name: relayName.value, accountNumber: accountNum)
            paymentSlip.remitter(remitter: remitter)
            let cashAmount = accountNum.toAccountCurrency()
            do {
                try paymentSlip.depositAmount(amount: cashAmount)
            } catch {
                return Single.error(PaymentException.InvalidDepositAmount())
            }
            let request = paymentSlip.build()
            return depositUseCase.depositOnline(paymentGateway: selectedGateway, depositRequest: request, provider: selectedGateway.provider, depositTypeId: depositTypeId, toBank: "")
        }
        return Single.never()
    }
    
    func getDepositPaymentGateways(depositType: DepositType) -> Single<[PaymentGateway]> {
        return depositUseCase.getPaymentGayway(depositType: depositType)
    }
    
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail> {
        return depositUseCase.getDepositRecordDetail(transactionId: transactionId)
    }
    
    func requestCryptoDepositUpdate(displayId: String) -> Single<String> {
        return depositUseCase.requestCryptoDetailUpdate(displayId: displayId)
    }
    
    func event() -> (bankValid: Observable<AccountNameException?>,
                     userNameValid: Observable<AccountNameException?>,
                     bankNumberValid: Observable<Bool>,
                     amountValid: Observable<Bool>,
                     offlineDataValid: Observable<Bool>,
                     onlinieDataValid: Observable<Bool>) {
        let userNameValid = relayName.map {(name) -> AccountNameException? in
            if name.isEmpty {
                return AccountNameException.EmptyAccountName()
            } else if name.count > 30 {
                return AccountNameException.ExceededLength()
            } else {
                return nil
            }
        }
        
        let isUserNameValid = userNameValid.map{ $0 == nil }
        
        let bankValid = relayBankName.map { name -> AccountNameException? in
            if name.isEmpty {
                return AccountNameException.EmptyAccountName()
            } else if name.count > 30 {
                return AccountNameException.ExceededLength()
            } else {
                return nil
            }
        }
        
        let isbankValid = bankValid.map{ $0 == nil }
        
        let bankNumberValid = relayBankNumber.map { (bankNumber) -> Bool in
            return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: bankNumber))
        }
        
        var amountValid: Observable<Bool>
        
        let offlineAmountValid = relayBankAmount.map({ [weak self](amount) -> Bool in
            guard let `self` = self,  let amount = Double(amount.replacingOccurrences(of: ",", with: "")) else { return false }
            let limitation = self.selectedType.method.limitation
            if limitation.min <= amount.toAccountCurrency() && amount.toAccountCurrency() <= limitation.max {
                return true
            } else {
                return false
            }
        })
        
        let onlineAmountValid = Observable.combineLatest(subjectGateway.flatMap({ [unowned self] (gateway) -> BehaviorRelay<String> in
            if self.needCashOption(gateway: gateway) {
                return self.dropdownAmount
            } else {
                return self.relayBankAmount
            }
        }), paymentSlip).map({ (amount, paymentSlip) -> Bool in
            guard let amount = Double(amount.replacingOccurrences(of: ",", with: "")) else { return false }
            return paymentSlip?.verifyDepositLimitation(amount: amount.toAccountCurrency()) ?? false
        })
        
        if selectedType.supportType == .OfflinePayment {
            amountValid = offlineAmountValid
        } else {
            amountValid = onlineAmountValid
        }
        let offlineDataValid = Observable.combineLatest(isUserNameValid, isbankValid, bankNumberValid, amountValid) {
            return $0 && $1 && $2 && $3
        }
        
        let onlinieDataValid = Observable.combineLatest(isUserNameValid, bankNumberValid, amountValid) {
            return $0 && $1 && $2
        }
        
        return (bankValid, userNameValid, bankNumberValid, amountValid, offlineDataValid, onlinieDataValid)
    }
    
    func getBankIcon(_ bankId: Int32) -> String {
        let language = Language(rawValue: LocalizeUtils.shared.getLanguage())
        switch language {
        case .ZH:
            return "CNY-\(bankId)"
        case .TH:
            return "THB-\(bankId)"
        case .VI:
            return "VND-\(bankId)"
        default:
            return ""
        }
    }
    
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return depositUseCase.bindingImageWithDepositRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
    
    func getDepositRecords(page: String = "1") -> Observable<[DepositRecord]> {
        let beginDate = (self.dateBegin ?? Date().getPastSevenDate())
        let endDate = (self.dateEnd ?? Date().convertdateToUTC())
        return depositUseCase.getDepositRecords(page: page, dateBegin: beginDate, dateEnd: endDate, status: self.status).asObservable()
    }
    
    func getCashLogSummary(balanceLogFilterType: Int) -> Single<[String: Double]> {
        let beginDate = self.dateBegin ?? Date().getPastSevenDate()
        let endDate = self.dateEnd ?? Date().convertdateToUTC()
        return playerUseCase.getCashLogSummary(begin: beginDate, end: endDate, balanceLogFilterType: balanceLogFilterType)
    }
    
    func createCryptoDeposit(cryptoDepositRequest: CryptoDepositRequest) -> Single<String> {
        return depositUseCase.requestCryptoDeposit(cryptoDepositRequest: cryptoDepositRequest)
    }
    
    func needCashOption(gateway: PaymentGateway) -> Bool {
        if selectedType.supportType == .WechatScan, gateway.provider == PaymentProvider.weilai {
            return true
        }
        return false
    }
}
