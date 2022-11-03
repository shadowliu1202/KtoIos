import Foundation
import RxSwift
import SharedBu
import RxSwiftExt
import RxCocoa

final class ServiceStatusViewModel: ViewModelType {
    private let systemStatusUseCase: GetSystemStatusUseCase
    private let localStorageRepo: LocalStorageRepository
    private let playerDefaultProductType = ReplaySubject<ProductType>.create(bufferSize: 1)
    private var countDownTimer: CountDownTimer?

    private(set) var input: Input!
    private(set) var output: Output!
    
    init(systemStatusUseCase: GetSystemStatusUseCase,
         localStorageRepo: LocalStorageRepository) {
        self.systemStatusUseCase = systemStatusUseCase
        self.localStorageRepo = localStorageRepo
        
        let otpService = systemStatusUseCase.getOtpStatus()
        let customerServiceEmail = systemStatusUseCase.getCustomerServiceEmail().asDriver(onErrorJustReturn: "")
        let maintainStatus = systemStatusUseCase.observePortalMaintenanceState()
        let maintainStatusPerSecond = systemStatusUseCase.observePortalMaintenanceState()
            .do(onNext: { [weak self] status in
                switch status {
                case let allPortal as MaintenanceStatus.AllPortal:
                    self?.timeOfRefresh(seconds: allPortal.convertDurationToSeconds()?.int32Value)
                default:
                    self?.countDownTimer?.stop()
                    break
                }
            })

        let playerDefaultType = playerDefaultProductType.asDriver(onErrorJustReturn: .none)
        let productMaintainTime = self.productMaintainTime(maintainStatus)
        let productsMaintainTime = self.productsMaintainTime(maintainStatus)
        
        self.output = Output(
            portalMaintenanceStatus: maintainStatus,
            portalMaintenanceStatusPerSecond: maintainStatusPerSecond,
            otpService: otpService,
            customerServiceEmail: customerServiceEmail,
            productMaintainTime: productMaintainTime,
            productsMaintainTime: productsMaintainTime
        )
        self.input = Input(playerDefaultProductType: playerDefaultProductType.asObserver())
    }
    
    private func timeOfRefresh(seconds: Int32?) {
        guard countDownTimer == nil else { return }
        countDownTimer = CountDownTimer()
        countDownTimer?.repeat(timeInterval: 1, block: { [weak self] _ in
            self?.refreshProductStatus()
        })
    }
    
    func refreshProductStatus() {
        systemStatusUseCase.refreshMaintenanceState()
    }
    
    private func productMaintainTime(_ maintainStatus: Observable<MaintenanceStatus>) -> SharedSequence<DriverSharingStrategy, OffsetDateTime?> {
        return playerDefaultProductType
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
    
    private func productsMaintainTime(_ maintainStatus: Observable<MaintenanceStatus>) -> Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]> {
        let productTypes: [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
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
