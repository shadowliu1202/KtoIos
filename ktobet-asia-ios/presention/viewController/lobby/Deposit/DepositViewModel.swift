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
    private var usecaseAuth: AuthenticationUseCase!
    private var playerUseCase: PlayerDataUseCase!
    private var bankUseCase: BankUseCase!
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
    var selectedReceiveBank: FullBankAccount!
    var selectedMethod: DepositRequest.DepositTypeMethod! {
        didSet {
            self.subjectMethod.onNext(selectedMethod)
        }
    }
    private var subjectMethod = PublishSubject<DepositRequest.DepositTypeMethod>()
    var minAmountLimit: Double = 0
    var maxAmountLimit: Double = 0
    var pagination: Pagination<DepositRecord>!
    var selectedType: DepositRequest.DepositType!
    let imgIcon: [Int32: String] = [0: Localize.string("Topup ¥(32)"),
                                    1: "UnionPay(32)",
                                    2: "WeChatPay(32)",
                                    3: "AliPay(32)",
                                    5: "秒存(32)",
                                    6: "閃充(32)",
                                    11: "雲閃付(32)",
                                    14: "iconPayMultiple",
                                    2001: "Ethereum"]
    init(depositUseCase: DepositUseCase, usecaseAuth: AuthenticationUseCase, playerUseCase: PlayerDataUseCase, bankUseCase: BankUseCase) {
        self.depositUseCase = depositUseCase
        self.usecaseAuth = usecaseAuth
        self.playerUseCase = playerUseCase
        self.bankUseCase = bankUseCase
        relayName.accept(usecaseAuth.getUserName())
        
        pagination = Pagination<DepositRecord>(callBack: {(page) -> Observable<[DepositRecord]> in
            self.getDepositRecords(page: String(page))
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError({ error -> Observable<[DepositRecord]> in
                    Observable.empty()
                })
        })
    }
    
    func getDepositType() -> Single<[DepositRequest.DepositType]> {
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
    
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]> {
        return depositUseCase.getDepositOfflineBankAccounts().map { $0.sorted { (f1, f2) -> Bool in
            guard let b1 = f1.bank, let b2 = f2.bank else { return false }
            return b1.shortName < b2.shortName
        } }
    }
    
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String> {
        return depositUseCase.depositOffline(depositRequest: depositRequest, depositTypeId: depositTypeId)
    }
    
    func depositOnline(depositTypeId: Int32) -> Single<String> {
        let accountNum = needCashOption(method: selectedMethod) ? dropdownAmount.value : relayBankAmount.value
        let remitter = DepositRequest.Remitter.init(name: relayName.value, accountNumber: accountNum, bankName: relayBankName.value)
        let cashAmount = CashAmount(amount: Double(accountNum.replacingOccurrences(of: ",", with: ""))!)
        let request = DepositRequest.Builder.init(paymentToken: selectedMethod.paymentTokenId).remitter(remitter: remitter).build(depositAmount: cashAmount)
        return depositUseCase.depositOnline(depositRequest: request, provider: selectedMethod.provider, depositTypeId: depositTypeId)
    }
    
    func getDepositMethods(depositType: Int32) -> Single<[DepositRequest.DepositTypeMethod]> {
        return depositUseCase.getDepositMethods(depositType: depositType)
    }
    
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail> {
        return depositUseCase.getDepositRecordDetail(transactionId: transactionId)
    }
    
    func requestCryptoDepositUpdate(displayId: String) -> Single<String> {
        return depositUseCase.requestCryptoDetailUpdate(displayId: displayId)
    }
    
    func event() -> (bankValid: Observable<Bool>,
                     userNameValid: Observable<Bool>,
                     bankNumberValid: Observable<Bool>,
                     amountValid: Observable<Bool>,
                     offlineDataValid: Observable<Bool>,
                     onlinieDataValid: Observable<Bool>) {
        let userNameValid = relayName.map { (name) -> Bool in
            return name.count != 0
        }
        
        let bankValid = relayBankName.map { (bank) -> Bool in
            return bank.count != 0
        }
        
        let bankNumberValid = relayBankNumber.map { (bankNumber) -> Bool in
            return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: bankNumber))
        }
        
        let amountValid = subjectMethod.flatMap({ [unowned self] (method) -> BehaviorRelay<String> in
            if self.needCashOption(method: method) {
                return self.dropdownAmount
            } else {
                return self.relayBankAmount
            }
        }).map { [unowned self] (amount) -> Bool in
            guard let amount = Double(amount.replacingOccurrences(of: ",", with: "")) else { return false }
            var minAmountLimit: Double = 0
            var maxAmountLimit: Double = 0
            if selectedType is DepositRequest.DepositTypeOffline {
                minAmountLimit = selectedType.min.amount
                maxAmountLimit = selectedType.max.amount
            } else {
                let range = selectedType.getDepositRange(method: selectedMethod)
                minAmountLimit = range.min.amount
                maxAmountLimit = range.max.amount
            }
            
            if minAmountLimit <= amount && amount <= maxAmountLimit {
                return true
            } else {
                return false
            }
        }
        
        let offlineDataValid = Observable.combineLatest(userNameValid, bankValid, bankNumberValid, amountValid) {
            return $0 && $1 && $2 && $3
        }
        
        let onlinieDataValid = Observable.combineLatest(userNameValid, bankNumberValid, amountValid) {
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
    
    func createCryptoDeposit() -> Single<String> {
        return depositUseCase.requestCryptoDeposit()
    }
    
    func needCashOption(method: DepositRequest.DepositTypeMethod) -> Bool {
        if method.depositTypeId == SupportDepositType.WechatScan.rawValue, method.provider == PaymentProvider_.weilai {
            return true
        }
        return false
    }
}
