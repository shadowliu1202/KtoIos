import Foundation
import RxSwift
import share_bu
import RxCocoa

class DepositViewModel {
    static let imageLimitSize = 20000000
    private var depositUseCase: DepositUseCase!
    private var usecaseAuth: AuthenticationUseCase!
    private var playerUseCase: PlayerDataUseCase!
    private var httpClient : HttpClient!
    let refreshTrigger = PublishSubject<Void>()
    let loadNextPageTrigger = PublishSubject<Void>()
    let error = PublishSubject<Swift.Error>()
    let loading = BehaviorRelay<Bool>(value: false)
    let elements = BehaviorRelay<[(String, [DepositRecord])]>(value: [])
    var filterBanks = BehaviorRelay<[SimpleBank]>(value: [SimpleBank]())
    private let disposeBag = DisposeBag()
    var pageIndex: Int = 1
    var isLastData = false
    var dateBegin: Date?
    var dateEnd: Date?
    var status: [TransactionStatus] = []
    var relayBank = BehaviorRelay<String>(value: "")
    var relayName = BehaviorRelay<String>(value: "")
    var relayBankNumber = BehaviorRelay<String>(value: "")
    var relayBankAmount = BehaviorRelay<String>(value: "")
    var Allbanks: [SimpleBank] = []
    var uploadImageDetail: [Int: UploadImageDetail] = [:]
    var selectedReceiveBank: FullBankAccount!
    var selectedMethod: DepositRequest.DepositTypeMethod?
    var selectedType: DepositRequest.DepositType!
    let imgIcon: [Int32: String] = [0: Localize.string("bank_offline_default"),
                                    1: "UnionPay(32)",
                                    2: "WeChatPay(32)",
                                    3: "AliPay(32)",
                                    5: "秒存(32)",
                                    6: "閃充(32)",
                                    11: "雲閃付(32)"]
    
    init(depositUseCase: DepositUseCase, usecaseAuth: AuthenticationUseCase, playerUseCase: PlayerDataUseCase, _ httpClient : HttpClient) {
        self.depositUseCase = depositUseCase
        self.usecaseAuth = usecaseAuth
        self.playerUseCase = playerUseCase
        self.httpClient = httpClient
        relayName.accept(usecaseAuth.getUserName())
        
        let refreshRequest = loading.asObservable()
            .sample(refreshTrigger)
            .flatMap { loading -> Observable<Int> in
                if loading {
                    return Observable.empty()
                } else {
                    self.pageIndex = 1
                    return Observable<Int>.create { observer in
                        observer.onNext(self.pageIndex)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
            }
        
        let nextPageRequest = loading.asObservable()
            .sample(loadNextPageTrigger)
            .flatMap { loading -> Observable<Int> in
                if loading {
                    return Observable.empty()
                } else if self.isLastData {
                    return Observable.empty()
                } else {
                    return Observable<Int>.create {  observer in
                        self.pageIndex += 1
                        observer.onNext(self.pageIndex)
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }
            }
        
        let request = Observable
            .of(refreshRequest, nextPageRequest)
            .merge()
            .share(replay: 1)
        
        let response = request.flatMap { page -> Observable<[(String, [DepositRecord])]> in
            self.getDepositRecords(page: String(page))
                .do(onError: { error in
                    self.error.onNext(error)
                }).catchError({ error -> Observable<[(String, [DepositRecord])]> in
                    Observable.empty()
                })
        }.share(replay: 1)
        
        Observable
            .combineLatest(request, response, elements.asObservable()) { request, response, elements in
                var responseDic = response.reduce(into: [:]) { $0[$1.0] = $1.1 }
                let elementsDic = elements.reduce(into: [:]) { $0[$1.0] = $1.1 }
                responseDic.merge(elementsDic, uniquingKeysWith: +)
                var groupData: [(String, [DepositRecord])] = responseDic.dictionaryToTuple()
                groupData = groupData.map { (key, value) -> (String, [DepositRecord]) in
                    var records: [DepositRecord] = []
                    records = value.sorted(by: { $0.createdDate.formatDateToStringToSecond() > $1.createdDate.formatDateToStringToSecond()})
                    return (key, records)
                }
                
                return (self.pageIndex == 1 ? response : groupData).sorted(by: { $0.0 > $1.0 })
            }
            .sample(response)
            .bind(to: elements)
            .disposed(by: disposeBag)
        
        Observable.of(request.map({ (response) -> Bool in
            return true
        }),
        response.map({ (response) -> Bool in
            self.isLastData = response.count == 0
            return false
        }),
        error.map({ (error) -> Bool in
            return false
        }))
        .merge()
        .bind(to: loading)
        .disposed(by: disposeBag)
    }
    
    func getDepositType() -> Single<[DepositRequest.DepositType]> {
        return depositUseCase.getDepositTypes()
    }
    
    func getDepositRecord() -> Single<[DepositRecord]> {
        return depositUseCase.getDepositRecords()
    }
    
    func getDepositTypeImage(depositTypeId: Int32) -> String? {
        return imgIcon[depositTypeId]
    }
    
    func getBanks() -> Single<[SimpleBank]> {
        return depositUseCase.getBank()
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
    
    func depositOnline(depositTypeId: Int32) -> Single<DepositTransaction> {
        let remitter = DepositRequest.Remitter.init(name: relayName.value, accountNumber: relayBankAmount.value, bankName: relayBank.value)
        let cashAmount = CashAmount(amount: Double(relayBankAmount.value.replacingOccurrences(of: ",", with: ""))!)
        let request = DepositRequest.Builder.init(paymentToken: selectedMethod!.paymentTokenId).remitter(remitter: remitter).build(depositAmount: cashAmount)
        return depositUseCase.depositOnline(depositRequest: request, depositTypeId: depositTypeId)
    }
    
    func getDepositMethods(depositType: Int32) -> Single<[DepositRequest.DepositTypeMethod]> {
        return depositUseCase.getDepositMethods(depositType: depositType)
    }
    
    func getDepositRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<DepositRecordDetail> {
        return depositUseCase.getDepositRecordDetail(transactionId: transactionId, transactionTransactionType: transactionTransactionType)
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
        
        let bankValid = relayBank.map { (bank) -> Bool in
            return bank.count != 0
        }
        
        let bankNumberValid = relayBankNumber.map { (bankNumber) -> Bool in
            return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: bankNumber))
        }
        
        let amountValid = relayBankAmount.map { [unowned self] (amount) -> Bool in
            guard let amount = Double(amount.replacingOccurrences(of: ",", with: "")) else { return false }
            var minAmountLimit: Double = 0
            var maxAmountLimit: Double = 0
            if selectedType is DepositRequest.DepositTypeOffline {
                minAmountLimit = selectedType.min.amount
                maxAmountLimit = selectedType.max.amount
            } else {
                let range = selectedType.getDepositRange(method: selectedMethod!)
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
    
    func getCookies() -> [HTTPCookie] {
        return self.httpClient.getCookies()
    }
    
    func getPaymentHost() -> String {
        return self.httpClient.getHost() + "payment-gateway"
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
    
    func getPastSevenDate() -> Date {
        var dateComponent = DateComponents()
        dateComponent.day = -6
        let pastSevenDate = Calendar.current.date(byAdding: dateComponent, to: Date())!
        return pastSevenDate.convertdateToUTC()
    }
    
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return depositUseCase.bindingImageWithDepositRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
    
    func getDepositRecords(page: String = "1") -> Observable<[(String, [DepositRecord])]> {
        let beginDate = (self.dateBegin ?? getPastSevenDate()).formatDateToStringToSecond(with: "-")
        let endDate = (self.dateEnd ?? Date().convertdateToUTC()).formatDateToStringToSecond(with: "-")
        return depositUseCase.getDepositRecords(page: page, dateBegin: beginDate, dateEnd: endDate, status: self.status).map { (records) -> [(String, [DepositRecord])] in
            let groupDic = Dictionary(grouping: records, by: { String(format: "%02d/%02d/%02d", $0.groupDay.year, $0.groupDay.monthNumber, $0.groupDay.dayOfMonth ) } )
            let groupData: [(String, [DepositRecord])] = groupDic.dictionaryToTuple()
            return groupData
        }.asObservable()
    }
    
    func getCashLogSummary(balanceLogFilterType: Int) -> Single<[String: Double]> {
        let beginDate = (self.dateBegin ?? getPastSevenDate()).formatDateToStringToSecond(with: "-")
        let endDate = (self.dateEnd ?? Date().convertdateToUTC()).formatDateToStringToSecond(with: "-")
        return playerUseCase.getCashLogSummary(begin: beginDate, end: endDate, balanceLogFilterType: balanceLogFilterType)
    }
}
