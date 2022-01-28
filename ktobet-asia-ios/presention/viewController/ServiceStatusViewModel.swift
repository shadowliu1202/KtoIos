import Foundation
import RxSwift
import SharedBu
import RxSwiftExt
import RxCocoa

final class ServiceStatusViewModel: ViewModelType {
    private var usecaseSystemStatus: GetSystemStatusUseCase!
    private let playerDefaultProductType = ReplaySubject<ProductType>.create(bufferSize: 1)
    
    private(set) var input: Input!
    private(set) var output: Output!
    
    init(usecaseSystemStatus: GetSystemStatusUseCase) {
        self.usecaseSystemStatus = usecaseSystemStatus
        
        let otpService = usecaseSystemStatus.getOtpStatus()
        let customerServiceEmail = usecaseSystemStatus.getCustomerServiceEmail().asDriver(onErrorJustReturn: "")
        let maintainStatus = usecaseSystemStatus.observePortalMaintenanceState().asDriver(onErrorJustReturn: .init())
        let playerDefaultType = playerDefaultProductType.asDriver(onErrorJustReturn: .none)
        let maintainDefaultType = self.maintainDefaultProductType(playerDefaultProductType: playerDefaultProductType, maintainStatus: maintainStatus)
        let isAllProductMaintain = maintainDefaultType.map { $0 == nil }.asDriver(onErrorJustReturn: false)
        let toNextPage = self.toNextPage(playerDefaultType, maintainDefaultType, isAllProductMaintain, maintainStatus)
        let productMaintainTime = self.productMaintainTime(maintainStatus)
        let productsMaintainTime = self.productsMaintainTime(maintainStatus)
        
        self.output = Output(playerDefaultType: playerDefaultType, maintainDefaultType: maintainDefaultType,
                             isAllProductMaintain: isAllProductMaintain, toNextPage: toNextPage,
                             portalMaintenanceStatus: maintainStatus, otpService: otpService,
                             customerServiceEmail: customerServiceEmail, productMaintainTime: productMaintainTime,
                             productsMaintainTime: productsMaintainTime)
        self.input = Input(playerDefaultProductType: playerDefaultProductType.asObserver())
    }
    
    func refreshProductStatus() {
        usecaseSystemStatus.refreshMaintenanceState()
    }
    
    private func toNextPage(_ playerDefaultType: Driver<ProductType>, _ maintainDefaultType: Driver<ProductType?>, _ isAllProductMaintain: Driver<Bool>, _ maintainStatus: Driver<MaintenanceStatus>) -> Completable {
        let navigator: ServiceStatusNavigator = ServiceStatusNavigatorImpl()
        return Driver.combineLatest(playerDefaultType, maintainDefaultType, isAllProductMaintain, maintainStatus)
            .do(onNext: { (playerType, maintainType, isAllProductMaintain, maintainStatus) in
            switch maintainStatus {
            case is MaintenanceStatus.AllPortal:
                navigator.toPortalMaintainPage()
            case is MaintenanceStatus.Product:
                if isAllProductMaintain {
                    navigator.toSBKMaintainPage()
                } else if maintainType != playerType {
                    navigator.toDefaultProductMaintainPage(playerType: playerType, maintainType: maintainType!)
                } else {
                    navigator.toPlayerProductPage(productType: playerType)
                }
            default:
                break
            }
        }).asObservable().ignoreElements()
    }

    private func maintainDefaultProductType(playerDefaultProductType: ReplaySubject<ProductType>, maintainStatus: Driver<MaintenanceStatus>) -> Driver<ProductType?> {
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
    
    private func productMaintainTime(_ maintainStatus: SharedSequence<DriverSharingStrategy, MaintenanceStatus>) -> SharedSequence<DriverSharingStrategy, OffsetDateTime?> {
        return playerDefaultProductType.flatMapLatest { playerDefaultProduct in
            maintainStatus.map { status -> OffsetDateTime? in
                if let status = status as? MaintenanceStatus.Product {
                    return status.getMaintenanceTime(productType: playerDefaultProduct)
                }
                
                return nil
            }
        }.asDriver(onErrorJustReturn: nil)
    }
    
    private func productsMaintainTime(_ maintainStatus: SharedSequence<DriverSharingStrategy, MaintenanceStatus>) -> Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]> {
        let productTypes: [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
        return maintainStatus.map { status -> [(productType: ProductType, maintainTime: OffsetDateTime?)] in
            if let status = status as? MaintenanceStatus.Product {
                return productTypes.map { ($0, status.getMaintenanceTime(productType: $0)) }
            }
            
            return []
        }.asObservable()
    }
}


extension ServiceStatusViewModel {
    struct Input {
        var playerDefaultProductType: AnyObserver<ProductType>
    }
    
    struct Output {
        let playerDefaultType: Driver<ProductType>
        let maintainDefaultType: Driver<ProductType?>
        let isAllProductMaintain: Driver<Bool>
        let toNextPage: Completable
        let portalMaintenanceStatus: Driver<MaintenanceStatus>
        let otpService: Single<OtpStatus>
        let customerServiceEmail: Driver<String>
        let productMaintainTime: Driver<OffsetDateTime?>
        let productsMaintainTime: Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]>
    }
}
