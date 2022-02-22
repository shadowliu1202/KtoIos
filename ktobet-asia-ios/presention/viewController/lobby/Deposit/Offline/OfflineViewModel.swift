import Foundation
import SharedBu
import RxSwift
import RxCocoa

class OfflineViewModel: KTOViewModel, ViewModelType {
    var accountPatternGenerator: AccountPatternGenerator!

    private(set) var input: Input!
    private(set) var output: Output!
    private var depositService: IDepositAppService!
    private var playerUseCase: PlayerDataUseCase!
    private var bankUseCase: BankUseCase!
    private var navigator: DepositNavigator!

    private let selectPaymentGateway = ReplaySubject<PaymentsDTO.BankCard>.create(bufferSize: 1)
    private let remitterBank = ReplaySubject<String>.create(bufferSize: 1)
    private let remitterName = ReplaySubject<String>.create(bufferSize: 1)
    private let remitterBankCardNumber = ReplaySubject<String>.create(bufferSize: 1)
    private let remittance = ReplaySubject<String>.create(bufferSize: 1)
    private let confirmTrigger = PublishSubject<Void>()
    private let depositTrigger = PublishSubject<Void>()
    private var inProgress = ActivityIndicator()

    init(_ depositService: IDepositAppService, playerUseCase: PlayerDataUseCase, accountPatternGenerator: AccountPatternGenerator, bankUseCase: BankUseCase, navigator: DepositNavigator) {
        super.init()
        self.depositService = depositService
        self.playerUseCase = playerUseCase
        self.accountPatternGenerator = accountPatternGenerator
        self.bankUseCase = bankUseCase
        self.navigator = navigator

        let payments = RxSwift.Observable.from(depositService.getPayments())
        let offlinePayment = payments.compactMap { $0.offline }
        let offlineBanks = offlinePayment.flatMapLatest { RxSwift.Single.from($0.beneficiaries) }.map { $0 as! [PaymentsDTO.BankCard] }

        let selectPaymentGateway = self.selectPaymentGateway.asDriverLogError()

        let offlinePaymentGateway = getOfflinePaymentGateway(offlineBanks: offlineBanks)
        let remitterBanks = getRemitterBanks(offlinePayment: offlinePayment)
        let remitterName = getPlayerRealName()
        let depositLimit = getDepositLimit(offlinePayment)
        let selectPaymentGatewayIcon = getBankIcon()

        let bankValid = isRemitterBankValid()
        let userNameValid = isRemitterNameValid()
        let bankNumberValid = isRemitterBankCardNumberValid()
        let amountValid = isRemittanceValid(depositLimit)
        let offlineDataValid = isOfflineDataValid(userNameValid: userNameValid,
                                                  bankValid: bankValid,
                                                  bankNumberValid: bankNumberValid,
                                                  amountValid: amountValid)
        let inProgress = self.inProgress.asDriver()
        let memo = confirm()
        let deposit = deposit(memo: memo)

        self.input = Input(selectPaymentGateway: self.selectPaymentGateway.asObserver(),
                           remitterBank: remitterBank.asObserver(),
                           remitterName: self.remitterName.asObserver(),
                           remitterBankCardNumber: remitterBankCardNumber.asObserver(),
                           amount: remittance.asObserver(),
                           confirmTrigger: confirmTrigger.asObserver(),
                           depositTrigger: depositTrigger.asObserver())
        self.output = Output(paymentGateway: offlinePaymentGateway,
                             selectPaymentGateway: selectPaymentGateway,
                             selectPaymentGatewayIcon: selectPaymentGatewayIcon,
                             remitterBanks: remitterBanks,
                             remitterName: remitterName,
                             memo: memo,
                             depositLimit: depositLimit,
                             bankValid: bankValid,
                             userNameValid: userNameValid,
                             bankNumberValid: bankNumberValid,
                             amountValid: amountValid,
                             offlineDataValid: offlineDataValid,
                             deposit: deposit,
                             inProgress: inProgress)
    }

    private func getOfflinePaymentGateway(offlineBanks: Observable<[PaymentsDTO.BankCard]>) -> Driver<[OfflinePaymentGatewayItemViewModel]> {
        let offlinePaymentGateway = Observable.combineLatest(offlineBanks, bankUseCase.getBankMap().asObservable()).map { (offline, banks) -> [PaymentsDTO.BankCard] in
            let sorted = banks.sorted { b1, b2 in
                b1.1.shortName < b2.1.shortName
            }.map { $0.1.bankId }

            var bankCards: [PaymentsDTO.BankCard] = []
            for s in sorted {
                for o in offline {
                    if o.bankId == String(s) {
                        bankCards.append(o)
                        break
                    }
                }
            }

            return bankCards
        }.do(onNext: { [weak self] bank in self?.selectPaymentGateway.onNext(bank.first!) })

        return Observable.combineLatest(offlinePaymentGateway, selectPaymentGateway).map { (banks, selectedBank) in
            banks.map { OfflinePaymentGatewayItemViewModel(with: $0, icon: self.getIconNamed($0.bankId), isSelected: $0 == selectedBank) }
        }.compose(self.applyObservableErrorHandle()).asDriverLogError()
    }

    private func getBankIcon() -> Driver<UIImage?> {
        selectPaymentGateway.map { [unowned self] in
            UIImage(named: self.getIconNamed($0.bankId))
        }.asDriverLogError()
    }

    private func getIconNamed(_ bankId: String) -> String {
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

    private func getDepositLimit(_ offlinePayment: Observable<PaymentsDTO.Offline>) -> SharedSequence<DriverSharingStrategy, AmountRange> {
        return offlinePayment.map { $0.depositLimit }.asDriverLogError()
    }

    private func getRemitterBanks(offlinePayment: Observable<PaymentsDTO.Offline>) -> Driver<[PaymentsDTO.Bank]> {
        offlinePayment.map { $0.availableBank }
            .compose(self.applyObservableErrorHandle())
            .asDriver(onErrorJustReturn: [])
    }

    private func getPlayerRealName() -> Driver<String> {
        playerUseCase.getPlayerRealName()
            .do(onSuccess: { [weak self] name in self?.remitterName.onNext(name) })
            .compose(self.applySingleErrorHandler())
            .asDriver(onErrorJustReturn: "")
    }

    private func isRemitterBankValid() -> Driver<AccountNameException?> {
        remitterBank.map { name -> AccountNameException? in
            if name.isEmpty {
                return AccountNameException.EmptyAccountName()
            } else if name.count > 30 {
                return AccountNameException.ExceededLength()
            } else {
                return nil
            }
        }.asDriver(onErrorJustReturn: nil)
    }

    private func isRemitterBankCardNumberValid() -> Driver<Bool> {
        remitterBankCardNumber.map { (bankNumber) -> Bool in
            CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: bankNumber))
        }.asDriver(onErrorJustReturn: false)
    }

    private func isRemittanceValid(_ depositLimit: Driver<AmountRange>) -> Driver<AmountExpection?> {
        Driver.combineLatest(depositLimit, remittance.asDriverLogError()).map({ (limitation, amount) -> AmountExpection? in
            guard let amount = Double(amount.replacingOccurrences(of: ",", with: "")) else { return AmountExpection.empty }
            if (limitation.min as! AccountCurrency) <= amount.toAccountCurrency() && amount.toAccountCurrency() <= (limitation.max as! AccountCurrency) {
                return nil
            } else {
                return AmountExpection.overLimitation
            }
        })
    }

    private func isRemitterNameValid() -> Driver<AccountNameException?> {
        self.remitterName.map { (name) -> AccountNameException? in
            if name.isEmpty {
                return AccountNameException.EmptyAccountName()
            } else if name.count > 30 {
                return AccountNameException.ExceededLength()
            } else {
                return nil
            }
        }.asDriver(onErrorJustReturn: nil)
    }

    private func isOfflineDataValid(userNameValid: Driver<AccountNameException?>,
                                    bankValid: Driver<AccountNameException?>,
                                    bankNumberValid: Driver<Bool>,
                                    amountValid: Driver<AmountExpection?>) -> Driver<Bool> {
        let isUserNameValid = userNameValid.map { $0 == nil }
        let isbankValid = bankValid.map { $0 == nil }
        let isAmountValid = amountValid.map { $0 == nil }
        return Driver.combineLatest(isUserNameValid, isbankValid, bankNumberValid, isAmountValid) {
            $0 && $1 && $2 && $3
        }
    }

    private func confirm() -> Driver<OfflineDepositDTO.Memo> {
        let request = Driver.combineLatest(selectPaymentGateway.asDriverLogError(),
                                           remitterBank.asDriverLogError(),
                                           remitterName.asDriverLogError(),
                                           remitterBankCardNumber.asDriverLogError(),
                                           remittance.asDriverLogError())
        { (selectOfflinePaymentGateway, remitterBank, remitterName, remitterBankCardNumber, amount) -> OfflineDepositDTO.Request in
            let amount = Int64(amount.replacingOccurrences(of: ",", with: "")) ?? 0
            let beneficiaryBankCardIdentity = selectOfflinePaymentGateway.identity
            let remitter = OfflineRemitter(name: remitterName, account: remitterBankCardNumber, bankName: remitterBank)
            let application = OfflineRemitApplication(remitter: remitter, remittance: amount, beneficiaryIdentity: beneficiaryBankCardIdentity)
            let request = OfflineDepositDTO.Request(application: application)
            return request
        }

        let memo = confirmTrigger.withLatestFrom(request)
            .flatMapLatest { [unowned self] request in
            Observable.from(depositService.requestOfflineDeposit(request: request)).compose(self.applyObservableErrorHandle())
        }.do(onNext: { [weak self] memo in self?.navigator.toDepositOfflineConfirmPage() }).asDriverLogError()

        return memo
    }

    private func deposit(memo: Driver<OfflineDepositDTO.Memo>) -> Driver<Bool> {
        depositTrigger.withLatestFrom(memo).flatMapLatest { [unowned self] memo in
            Completable.from(CompletableWrapperKt.wrap(self.depositService.confirmOfflineDeposit(beneficiaryIdentity: memo.identity))).andThen(Single.just(true)).compose(self.applySingleErrorHandler()).asDriver(onErrorJustReturn: false).trackActivity(self.inProgress)
        }
        .do(onNext: { [weak self] _ in
            self?.navigator.toDepositHomePage()
        }).asDriverLogError()
    }
}

extension OfflineViewModel {
    struct Input {
        let selectPaymentGateway: AnyObserver<PaymentsDTO.BankCard>
        let remitterBank: AnyObserver<String>
        let remitterName: AnyObserver<String>
        let remitterBankCardNumber: AnyObserver<String>
        let amount: AnyObserver<String>
        let confirmTrigger: AnyObserver<Void>
        let depositTrigger: AnyObserver<Void>
    }

    struct Output {
        let paymentGateway: Driver<[OfflinePaymentGatewayItemViewModel]>
        let selectPaymentGateway: Driver<PaymentsDTO.BankCard>
        let selectPaymentGatewayIcon: Driver<UIImage?>
        let remitterBanks: Driver<[PaymentsDTO.Bank]>
        let remitterName: Driver<String>
        let memo: Driver<OfflineDepositDTO.Memo>
        let depositLimit: Driver<AmountRange>
        let bankValid: Driver<AccountNameException?>
        let userNameValid: Driver<AccountNameException?>
        let bankNumberValid: Driver<Bool>
        let amountValid: Driver<AmountExpection?>
        let offlineDataValid: Driver<Bool>
        let deposit: Driver<Bool>
        let inProgress: Driver<Bool>
    }
}

enum AmountExpection {
    case overLimitation
    case empty
}
