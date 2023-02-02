import Foundation
import SharedBu
import RxSwiftExt
import RxSwift
import RxCocoa

final class ThirdPartyDepositViewModel: CollectErrorViewModel, ViewModelType {
    private(set) var input: Input!
    private(set) var output: Output!

    private var playerUseCase: PlayerDataUseCase!
    private var depositService: IDepositAppService!
    private var navigator: DepositNavigator!
    private var httpClient: HttpClient!
    private let paymentIdentity = ReplaySubject<String>.create(bufferSize: 1)
    private let selectPaymentGateway = ReplaySubject<PaymentsDTO.Gateway>.create(bufferSize: 1)
    private let selectBankCode = ReplaySubject<String?>.create(bufferSize: 1)
    private let remitterName = ReplaySubject<String>.create(bufferSize: 1)
    private let remittance = ReplaySubject<String>.create(bufferSize: 1)
    private let remitterBankCardNumber = ReplaySubject<String>.create(bufferSize: 1)
    private let confirmTrigger = PublishSubject<Void>()
    private let errors = PublishSubject<Error>()
    private var inProgress = ActivityIndicator()

    init(playerUseCase: PlayerDataUseCase, depositService: IDepositAppService, navigator: DepositNavigator, httpClient: HttpClient) {
        super.init()
        self.playerUseCase = playerUseCase
        self.depositService = depositService
        self.navigator = navigator
        self.httpClient = httpClient

        let paymentGateways = getPaymentGateways()
        let remittance = self.remittance.asDriverLogError()
        let remitterName = getPlayerRealName()
        let depositLimit = getDepositLimit()
        let depositAmountHint = getDepositAmountHint()
        let cashOption = getCashOption()
        let floatAllow = getCashTypeInput()

        let remitterNameValid = isRemitterNameValid()
        let remitterBankCardNumbeValid = isRemitterBankCardNumbeValid()
        let remittanceValid = isRemittanceValid(depositLimit)
        let onlineDataValid = isOnlineDataValid(remitterNameValid: remitterNameValid, bankNumberValid: remitterBankCardNumbeValid, remittanceValid: remittanceValid)

        let inProgress = self.inProgress.asDriver()
        let webPath = confirm()

        self.input = Input(paymentIdentity: paymentIdentity.asObserver(),
                           selectPaymentGateway: selectPaymentGateway.asObserver(),
                           selectBankCode: selectBankCode.asObserver(),
                           remittance: self.remittance.asObserver(),
                           remitterName: self.remitterName.asObserver(),
                           remitterBankCardNumber: remitterBankCardNumber.asObserver(),
                           confirmTrigger: confirmTrigger.asObserver())

        self.output = Output(paymentGateways: paymentGateways,
                             selectPaymentGateway: selectPaymentGateway.asDriverLogError(),
                             depositLimit: depositLimit,
                             depositAmountHintText: depositAmountHint,
                             remitterName: remitterName,
                             remittance: remittance,
                             cashOption: cashOption,
                             floatAllow: floatAllow,
                             remitterNameValid: remitterNameValid,
                             remitterBankCardNumbeValid: remitterBankCardNumbeValid,
                             remittanceValid: remittanceValid,
                             onlineDataValid: onlineDataValid,
                             webPath: webPath,
                             inProgress: inProgress)
    }

    private func getPaymentGateways() -> Driver<[OnlinePaymentGatewayItemViewModel]> {
        let payments = RxSwift.Observable.from(depositService.getPayments())
        let onlinePaymentGateway = paymentIdentity.flatMapLatest { identity in
            payments.compactMap { $0.fiat.first(where: { $0.identity == identity }) }
        }

        let _paymentGateways = onlinePaymentGateway.flatMapLatest { RxSwift.Single.from($0.beneficiaries) }
            .map { $0 as! [PaymentsDTO.Gateway] }
            .compose(self.applyObservableErrorHandle())
            .do(onNext: { [weak self] gateway in self?.selectPaymentGateway.onNext(gateway.first!) })

        let paymentGateways = Observable.combineLatest(_paymentGateways, selectPaymentGateway)
            .map { (paymentGateways, selectPaymentGateway) in
                paymentGateways
                    .map { gatewayDTO in
                        OnlinePaymentGatewayItemViewModel(
                            with: gatewayDTO,
                            isSelected: gatewayDTO == selectPaymentGateway
                        )
                    }
            }
            .asDriverLogError()

        return paymentGateways
    }

    private func getPlayerRealName() -> Driver<String> {
        playerUseCase.getPlayerRealName()
            .compose(self.applySingleErrorHandler())
            .do(onSuccess: { [weak self] name in self?.remitterName.onNext(name) })
            .asDriver(onErrorJustReturn: "")
    }

    private func getDepositLimit() -> Driver<AmountRange?> {
        selectPaymentGateway.map { gateway -> AmountRange? in
            switch gateway.cash {
            case let input as CashType.Input:
                return input.limitation
            case let option as CashType.Option:
                return option.limitation
            default:
                return nil
            }
        }
        .compose(self.applyObservableErrorHandle())
        .asDriverLogError()
    }
    
    private func getDepositAmountHint() -> Driver<String> {
        selectPaymentGateway
            .map { gatewayDTO in
                switch gatewayDTO.cash {
                case let input as CashType.Input:
                    let amountRange = input.limitation
                    
                    return String(format: Localize.string("deposit_offline_step1_tips"),
                                  amountRange.min.description(),
                                  amountRange.max.description())
                    
                case _ as CashType.Option:
                    return Localize.string("deposit_amount_option_hint")
                    
                default:
                    return ""
                }
            }
            .asDriver(onErrorJustReturn: "")
    }
    
    private func getCashTypeInput() -> Driver<Bool?> {
        selectPaymentGateway.map { gateway -> Bool? in
            switch gateway.cash {
            case let input as CashType.Input:
                return input.isFloatAllowed
            default:
                return nil
            }
        }
        .distinctUntilChanged()
        .compose(self.applyObservableErrorHandle())
        .asDriverLogError()
    }

    private func getCashOption() -> SharedSequence<DriverSharingStrategy, [KotlinDouble]?> {
        selectPaymentGateway
            .map { ($0.cash as? CashType.Option)?.list }
            .do(onNext: { [weak self] list in
                guard let self = self, let first = list?.first else { return }
                let firstOptionString = first.decimalValue.currencyFormatWithoutSymbol(maximumFractionDigits: 0)
                self.remittance.onNext(firstOptionString)
            }).compose(self.applyObservableErrorHandle()).asDriverLogError()
    }

    private func isRemittanceValid(_ depositLimit: Driver<AmountRange?>) -> Driver<AmountExpection?> {
        Driver.combineLatest(depositLimit, remittance.asDriverLogError()).map({ (limitation, amount) -> AmountExpection? in
            guard let limitation = limitation else { return nil }
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

    private func isRemitterBankCardNumbeValid() -> SharedSequence<DriverSharingStrategy, Bool> {
        return remitterBankCardNumber.map { (bankNumber) -> Bool in
            CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: bankNumber))
        }.asDriver(onErrorJustReturn: false)
    }

    private func isOnlineDataValid(remitterNameValid: Driver<AccountNameException?>,
                                   bankNumberValid: Driver<Bool>,
                                   remittanceValid: Driver<AmountExpection?>) -> Driver<Bool> {
        let isRemitterNameValid = remitterNameValid.map { $0 == nil }
        let isRemittanceValid = remittanceValid.map { $0 == nil }
        return Driver.combineLatest(isRemitterNameValid, bankNumberValid, isRemittanceValid) {
            $0 && $1 && $2
        }
    }

    private func createRequest() -> Driver<OnlineDepositDTO.Request> {
        Driver.combineLatest(paymentIdentity.asDriverLogError(),
                             selectPaymentGateway.asDriverLogError(),
                             selectBankCode.asDriverLogError(),
                             remitterName.asDriverLogError(),
                             remitterBankCardNumber.asDriverLogError(),
                             remittance.asDriverLogError())
        { (paymentIdentity, selectPaymentGateway, selectBankCode, remitterName, remitterBankCardNumber, remittance) in
            let amount = remittance.replacingOccurrences(of: ",", with: "")
            let onlineRemitter = OnlineRemitter(name: remitterName, account: remitterBankCardNumber)
            let application = OnlineRemitApplication(remitter: onlineRemitter, remittance: amount, gatewayIdentity: selectPaymentGateway.identity, supportBankCode: selectBankCode)
            let request = OnlineDepositDTO.Request(paymentIdentity: paymentIdentity, application: application)
            return request
        }
    }

    private func confirm() -> Driver<CommonDTO.WebPath> {
        confirmTrigger.withLatestFrom(createRequest())
            .flatMapLatest { [unowned self] request -> Single<CommonDTO.WebPath> in
                Single.from(self.depositService.requestOnlineDeposit(request: request))
                    .observe(on: MainScheduler.instance)
                    .compose(self.applySingleErrorHandler())
                    .trackActivity(self.inProgress)
        }.do(onNext: { [weak self] url in
            guard let host = self?.httpClient.host.absoluteString else { return }
            let url = host + url.path + "&backUrl=\(host)" 
            self?.navigator.toOnlineWebPage(url: url)
        }).asDriverLogError()
    }
}

extension ThirdPartyDepositViewModel {
    struct Input {
        let paymentIdentity: AnyObserver<String>
        let selectPaymentGateway: AnyObserver<PaymentsDTO.Gateway>
        let selectBankCode: AnyObserver<String?>
        let remittance: AnyObserver<String>
        let remitterName: AnyObserver<String>
        let remitterBankCardNumber: AnyObserver<String>
        let confirmTrigger: AnyObserver<Void>
    }

    struct Output {
        let paymentGateways: Driver<[OnlinePaymentGatewayItemViewModel]>
        let selectPaymentGateway: Driver<PaymentsDTO.Gateway>
        let depositLimit: Driver<AmountRange?>
        let depositAmountHintText: Driver<String>
        let remitterName: Driver<String>
        let remittance: Driver<String>
        let cashOption: Driver<[KotlinDouble]?>
        let floatAllow: Driver<Bool?>
        let remitterNameValid: Driver<AccountNameException?>
        let remitterBankCardNumbeValid: Driver<Bool>
        let remittanceValid: Driver<AmountExpection?>
        let onlineDataValid: Driver<Bool>
        let webPath: Driver<CommonDTO.WebPath>
        let inProgress: Driver<Bool>
    }
}
