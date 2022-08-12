import Foundation
import RxSwift
import SharedBu
import RxSwiftExt
import RxCocoa

final class ServiceStatusViewModel: ViewModelType {
    private let systemStatusUseCase: GetSystemStatusUseCase
    private let localStorageRepo: PlayerLocaleConfiguration
    private let playerDefaultProductType = ReplaySubject<ProductType>.create(bufferSize: 1)
    private var countDownTimer: CountDownTimer?
    
    private(set) var input: Input!
    private(set) var output: Output!
    
    init(systemStatusUseCase: GetSystemStatusUseCase, localStorageRepo: PlayerLocaleConfiguration) {
        self.systemStatusUseCase = systemStatusUseCase
        self.localStorageRepo = localStorageRepo
        
        let otpService = systemStatusUseCase.getOtpStatus()
        let customerServiceEmail = systemStatusUseCase.getCustomerServiceEmail().asDriver(onErrorJustReturn: "")
        let maintainStatus = systemStatusUseCase.observePortalMaintenanceState()
        let maintainStatusPerSecond = systemStatusUseCase.observePortalMaintenanceState().do(onNext: { [weak self] status in
            switch status {
            case let allPortal as MaintenanceStatus.AllPortal:
                self?.timeOfRefresh(seconds: allPortal.convertDurationToSeconds()?.int32Value)
            default:
                self?.countDownTimer?.stop()
                break
            }
        })

        let playerDefaultType = playerDefaultProductType.asDriver(onErrorJustReturn: .none)
        let maintainDefaultType = self.maintainDefaultProductType(playerDefaultProductType: playerDefaultProductType, maintainStatus: maintainStatus)
        let productMaintainTime = self.productMaintainTime(maintainStatus)
        let productsMaintainTime = self.productsMaintainTime(maintainStatus)
        let maintainImage = self.getMaintainImage(productType: playerDefaultType)
        
        self.output = Output(maintainDefaultType: maintainDefaultType,
                             portalMaintenanceStatus: maintainStatus, portalMaintenanceStatusPerSecond: maintainStatusPerSecond, otpService: otpService,
                             customerServiceEmail: customerServiceEmail, productMaintainTime: productMaintainTime,
                             productsMaintainTime: productsMaintainTime, maintainImage: maintainImage)
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

    private func maintainDefaultProductType(playerDefaultProductType: ReplaySubject<ProductType>, maintainStatus: Observable<MaintenanceStatus>) -> Driver<ProductType?> {
        let productMaintenPriorityOrder: [ProductType] = [.sbk, .casino, .slot, .numbergame, .arcade, .p2p]
        return playerDefaultProductType.flatMapLatest { playerDefaultProduct in
            maintainStatus.map { status -> ProductType? in
                guard let productStatus = status as? MaintenanceStatus.Product else { return nil }
                if productStatus.isProductMaintain(productType: playerDefaultProduct) {
                    return productMaintenPriorityOrder.first { !productStatus.isProductMaintain(productType: $0) } ?? nil
                } else {
                    return playerDefaultProduct
                }
            }
        }.asDriver(onErrorJustReturn: nil)
    }
    
    private func productMaintainTime(_ maintainStatus: Observable<MaintenanceStatus>) -> SharedSequence<DriverSharingStrategy, OffsetDateTime?> {
        return playerDefaultProductType.flatMapLatest { playerDefaultProduct in
            maintainStatus.map { status -> OffsetDateTime? in
                if let status = status as? MaintenanceStatus.Product {
                    return status.getMaintenanceTime(productType: playerDefaultProduct)
                }
                
                return nil
            }
        }.asDriver(onErrorJustReturn: nil)
    }
    
    private func productsMaintainTime(_ maintainStatus: Observable<MaintenanceStatus>) -> Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]> {
        let productTypes: [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
        return maintainStatus.map { status -> [(productType: ProductType, maintainTime: OffsetDateTime?)] in
            if let status = status as? MaintenanceStatus.Product {
                return productTypes.map { ($0, status.getMaintenanceTime(productType: $0)) }
            }
            
            return []
        }.asObservable()
    }
    
    private func getMaintainImage(productType: Driver<ProductType>) -> Driver<String> {
        return productType.map { productType -> String in
            let language = Language(rawValue: self.localStorageRepo.getCultureCode())
            switch language {
            case .ZH:
                return "CNY-maintain\(productType.name)"
            case .TH:
                return "THB-\(productType.name)"
            case .VI:
                return "VND-maintain\(productType.name)"
            default:
                return ""
            }
        }
    }
}


extension ServiceStatusViewModel {
    struct Input {
        var playerDefaultProductType: AnyObserver<ProductType>
    }
    
    struct Output {
        let maintainDefaultType: Driver<ProductType?>
        let portalMaintenanceStatus: Observable<MaintenanceStatus>
        let portalMaintenanceStatusPerSecond: Observable<MaintenanceStatus>
        let otpService: Single<OtpStatus>
        let customerServiceEmail: Driver<String>
        let productMaintainTime: Driver<OffsetDateTime?>
        let productsMaintainTime: Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]>
        let maintainImage: Driver<String>
    }
}
