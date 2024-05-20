import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt
import sharedbu

class ServiceStatusViewModel {
    private let systemStatusUseCase: ISystemStatusUseCase
    private let localStorageRepo: LocalStorageRepository
    private let playerDefaultProductType = ReplaySubject<ProductType>.create(bufferSize: 1)
    private var countDownTimer: CountDownTimer?

    private(set) var input: Input!

    var output: Output!

    init(
        systemStatusUseCase: ISystemStatusUseCase,
        localStorageRepo: LocalStorageRepository)
    {
        self.systemStatusUseCase = systemStatusUseCase
        self.localStorageRepo = localStorageRepo

        let otpService = systemStatusUseCase.fetchOTPStatus()
        let customerServiceEmail = systemStatusUseCase.fetchCustomerServiceEmail().asDriver(onErrorJustReturn: "")
        let maintainStatus = systemStatusUseCase.observeMaintenanceStatusByFetch()
        let maintainStatusPerSecond = systemStatusUseCase.observeMaintenanceStatusByFetch()
            .do(onNext: { [weak self] status in
                switch onEnum(of: status) {
                case .allPortal(let it):
                    self?.timeOfRefresh(seconds: it.convertDurationToSeconds()?.int32Value)
                case .product:
                    self?.countDownTimer?.stop()
                }
            })

        let productMaintainTime = self.productMaintainTime(maintainStatus)
        let productsMaintainTime = self.productsMaintainTime(maintainStatus)

        self.output = Output(
            portalMaintenanceStatus: maintainStatus,
            portalMaintenanceStatusPerSecond: maintainStatusPerSecond,
            otpService: otpService,
            customerServiceEmail: customerServiceEmail,
            productMaintainTime: productMaintainTime,
            productsMaintainTime: productsMaintainTime)
        self.input = Input(playerDefaultProductType: playerDefaultProductType.asObserver())
    }

    private func timeOfRefresh(seconds _: Int32?) {
        guard countDownTimer == nil else { return }
        countDownTimer = CountDownTimer()
        countDownTimer?.repeat(timeInterval: 1, block: { [weak self] _ in
            self?.refreshProductStatus()
        })
    }

    func refreshProductStatus() {
        systemStatusUseCase.refreshMaintenanceState()
    }

    private func productMaintainTime(_ maintainStatus: Observable<MaintenanceStatus>)
        -> SharedSequence<DriverSharingStrategy, OffsetDateTime?>
    {
        playerDefaultProductType
            .flatMapLatest { playerDefaultProduct in
                maintainStatus.map { status -> OffsetDateTime? in
                    if let status = status as? MaintenanceStatus.Product {
                        return status.getMaintenanceTime(productType: playerDefaultProduct)
                    }

                    return nil
                }
            }
            .asDriver(onErrorJustReturn: nil)
    }

    private func productsMaintainTime(_ maintainStatus: Observable<MaintenanceStatus>)
        -> Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]>
    {
        let productTypes: [ProductType] = [.sbk, .casino, .slot, .numberGame, .p2P, .arcade]
        return maintainStatus
            .map { status -> [(productType: ProductType, maintainTime: OffsetDateTime?)] in
                if let status = status as? MaintenanceStatus.Product {
                    return productTypes.map { ($0, status.getMaintenanceTime(productType: $0)) }
                }

                return []
            }
            .asObservable()
    }
}

extension ServiceStatusViewModel {
    struct Input {
        var playerDefaultProductType: AnyObserver<ProductType>
    }

    struct Output {
        let portalMaintenanceStatus: Observable<MaintenanceStatus>
        let portalMaintenanceStatusPerSecond: Observable<MaintenanceStatus>
        let otpService: Single<OtpStatus>
        let customerServiceEmail: Driver<String>
        let productMaintainTime: Driver<OffsetDateTime?>
        let productsMaintainTime: Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]>
    }
}
