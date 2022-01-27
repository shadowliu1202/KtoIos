import Foundation
import RxSwift
import SharedBu
import RxSwiftExt
import RxCocoa


final class ServiceStatusViewModel: ViewModelType {
    private var usecaseSystemStatus: GetSystemStatusUseCase!
    private let playerDefaultProductSubject = ReplaySubject<ProductType>.create(bufferSize: 1)

    var input: Input
    var output: Output

    init(usecaseSystemStatus: GetSystemStatusUseCase) {
        self.usecaseSystemStatus = usecaseSystemStatus

        let otpService = usecaseSystemStatus.getOtpStatus()
        let customerServiceEmail = usecaseSystemStatus.getCustomerServiceEmail()
        let maintainStatus = usecaseSystemStatus.observePortalMaintenanceState().asDriver(onErrorJustReturn: .init())
        let playerDefaultType = playerDefaultProductSubject.asDriver(onErrorJustReturn: .none)
        let maintainDefaultType = ServiceStatusViewModel.maintainDefaultProductType(playerDefaultProductSubject: playerDefaultProductSubject, maintainStatus: maintainStatus)
        let isAllProductMaintain = maintainDefaultType.map { $0 == nil }.asDriver(onErrorJustReturn: false)
        let toNextPage = ServiceStatusViewModel.toNextPage(playerDefaultType, maintainDefaultType, isAllProductMaintain, maintainStatus)
        let productMaintainTime = playerDefaultProductSubject.flatMapLatest { playerDefaultProduct in
            maintainStatus.map { status -> OffsetDateTime? in
                if let status = status as? MaintenanceStatus.Product {
                    return status.getMaintenanceTime(productType: playerDefaultProduct)
                }
                
                return nil
            }
        }.asDriver(onErrorJustReturn: nil)
        
        let productTypes: [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
        let productsMaintainTime = maintainStatus.map { status -> [(productType: ProductType, maintainTime: OffsetDateTime?)] in
            if let status = status as? MaintenanceStatus.Product {
                return productTypes.map{ ($0, status.getMaintenanceTime(productType: $0)) }
            }
            
            return []
        }.asObservable()
        
        self.output = Output(playerDefaultType: playerDefaultType, maintainDefaultType: maintainDefaultType,
                             isAllProductMaintain: isAllProductMaintain, toNextPage: toNextPage,
                             portalMaintenanceStatus: maintainStatus, otpService: otpService,
                             customerServiceEmail: customerServiceEmail, maintainTime: productMaintainTime,
                             maintainTimes: productsMaintainTime)
        self.input = Input(playerDefaultProduct: playerDefaultProductSubject.asObserver())
    }

    func refreshProductStatus() {
        usecaseSystemStatus.refreshMaintenanceState()
    }

    private static func toNextPage(_ playerDefaultType: Driver<ProductType>, _ maintainDefaultType: Driver<ProductType?>, _ isAllProductMaintain: Driver<Bool>, _ maintainStatus: Driver<MaintenanceStatus>) -> Completable {
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
                    navigator.toPlayerType(playerType: playerType)
                }
            default:
                break
            }
        }).asObservable().ignoreElements()
    }

    private static func maintainDefaultProductType(playerDefaultProductSubject: ReplaySubject<ProductType>, maintainStatus: Driver<MaintenanceStatus>) -> Driver<ProductType?> {
        let productMaintenPriorityOrder: [ProductType] = [.sbk, .casino, .slot, .numbergame, .arcade, .p2p]
        return playerDefaultProductSubject.flatMapLatest { playerDefaultProduct in
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
}


extension ServiceStatusViewModel {
    struct Input {
        var playerDefaultProduct: AnyObserver<ProductType>
    }

    struct Output {
        let playerDefaultType: Driver<ProductType>
        let maintainDefaultType: Driver<ProductType?>
        let isAllProductMaintain: Driver<Bool>
        let toNextPage: Completable
        let portalMaintenanceStatus: Driver<MaintenanceStatus>
        let otpService: Single<OtpStatus>
        let customerServiceEmail: Single<String>
        let maintainTime: Driver<OffsetDateTime?>
        let maintainTimes: Observable<[(productType: ProductType, maintainTime: OffsetDateTime?)]>
    }
}
