import Foundation
import RxSwift
import RxCocoa
import SharedBu

final class CryptoDepositViewModel: KTOViewModel, ViewModelType {
    private(set) var input: Input!
    private(set) var output: Output!

    private var depositService: IDepositAppService!
    private var navigator: DepositNavigator!

    private let selectPaymentGateway = ReplaySubject<PaymentsDTO.TypeOptions>.create(bufferSize: 1)
    private let confirmTrigger = PublishSubject<Void>()

    init(depositService: IDepositAppService, navigator: DepositNavigator) {
        super.init()
        self.depositService = depositService
        self.navigator = navigator

        let payments = RxSwift.Observable.from(depositService.getPayments())
        let cryptoPayment = payments.compactMap { $0.crypto }
        let options = getCryptoOptions(cryptoPayment)
        let webUrl = request()

        self.input = Input(selectPaymentGateway: selectPaymentGateway.asObserver(),
                           confirmTrigger: confirmTrigger.asObserver())
        self.output = Output(options: options,
                             webUrl: webUrl)
    }

    private func getCryptoOptions(_ cryptoPayment: Observable<PaymentsDTO.Crypto>) -> Driver<[CryptoDepositItemViewModel]> {
        let options = cryptoPayment.flatMap { RxSwift.Single.from($0.options) }
            .map { $0 as! [PaymentsDTO.TypeOptions] }
            .compose(self.applyObservableErrorHandle())
            .asDriverLogError()
            .do(onNext: { [weak self] gateway in self?.selectPaymentGateway.onNext(gateway.first!) })

        return Driver.combineLatest(options, selectPaymentGateway.asDriverLogError()).map { (options, selectPaymentGateway) in
            options.map { CryptoDepositItemViewModel(with: $0, icon: self.getIconNamed($0.cryptoType), isSelected: $0 == selectPaymentGateway) }
        }
    }

    private func request() -> Driver<CommonDTO.WebUrl> {
        confirmTrigger.withLatestFrom(selectPaymentGateway.asDriverLogError()).flatMapLatest { [unowned self] selectedOption in
            Single.from(self.depositService.requestCryptoDeposit(request: CryptoDepositDTO.Request(typeOptionsId: selectedOption.optionsId))) }
            .do(onNext: { [weak self] webPath in self?.navigator.toCryptoWebPage(url: webPath.url) })
            .compose(self.applyObservableErrorHandle())
            .asDriver(onErrorJustReturn: CommonDTO.WebUrl(url: ""))
    }

    private func getIconNamed(_ type: PaymentsDTO.TypeOptionsType) -> String {
        switch type {
        case .eth:
            return "Main_ETH"
        case .usdt:
            return "Main_USDT"
        case .usdc:
            return "Main_USDC"
        default:
            return ""
        }
    }
}

extension CryptoDepositViewModel {
    struct Input {
        let selectPaymentGateway: AnyObserver<PaymentsDTO.TypeOptions>
        let confirmTrigger: AnyObserver<Void>
    }

    struct Output {
        let options: Driver<[CryptoDepositItemViewModel]>
        let webUrl: Driver<CommonDTO.WebUrl>
    }
}
