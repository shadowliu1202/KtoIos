import Foundation
import RxSwift
import SharedBu

class NavigationViewModel {
    typealias isLogged = Bool
    
    enum LobbyPageNavigation {
        case portalAllMaintenance
        case notLogin
        case playerDefaultProduct(ProductType)
        case alternativeProduct(ProductType, ProductType)
        case setDefaultProduct
    }
    
    private let alternativePriority: [ProductType] = [.sbk, .casino, .slot, .numbergame, .arcade, .p2p]
    private let authUseCase: AuthenticationUseCase!
    private let playerUseCase : PlayerDataUseCase!
    private let localizationPolicyUseCase: LocalizationPolicyUseCase!
    private let systemStatusUseCase: GetSystemStatusUseCase!
    
    init(_ authUseCase: AuthenticationUseCase,
         _ playerUseCase: PlayerDataUseCase,
         _ localizationPolicyUseCase: LocalizationPolicyUseCase,
         _ systemStatusUseCase: GetSystemStatusUseCase) {
        self.authUseCase = authUseCase
        self.playerUseCase = playerUseCase
        self.localizationPolicyUseCase = localizationPolicyUseCase
        self.systemStatusUseCase = systemStatusUseCase
    }
    
    func checkIsLogged() -> Single<isLogged>{
        authUseCase.isLogged()
    }
    
    func initLaunchNavigation() -> Single<LobbyPageNavigation> {
        return getLaunchNeededStatus().map { (status, isLogged, defaultType) in
            switch status {
            case is MaintenanceStatus.AllPortal:
                return .portalAllMaintenance
            case is MaintenanceStatus.Product:
                return self.getPageNavigation(isLogged, defaultType, status as! MaintenanceStatus.Product)
            default:
                fatalError("Should not reach here.")
            }
        }
    }
    
    private func getLaunchNeededStatus() -> Single<(MaintenanceStatus?, isLogged, ProductType?)> {
        return initLocale().andThen(Single.zip(systemStatusUseCase.observePortalMaintenanceState().first(), checkIsLogged()))
            .flatMap { (maintenanceStatus, isLogin) in
                if isLogin {
                    return self.loadDefaultProduct().map { (maintenanceStatus, isLogin, $0) }
                } else {
                    return Single.just((maintenanceStatus, isLogin, nil))
                }
            }
    }
    
    private func initLocale() -> Completable {
        localizationPolicyUseCase.initLocale()
    }
    
    private func loadDefaultProduct() -> Single<ProductType?> {
        playerUseCase.loadPlayer().map { $0.defaultProduct }
    }
    
    private func getPageNavigation(_ isLogged: Bool, _ defaultProduct: ProductType?, _ productStatus: MaintenanceStatus.Product) -> LobbyPageNavigation {
        isLogged ? getLobbyNavigation(defaultProduct, productStatus) : .notLogin
    }
    
    private func getLobbyNavigation(_ defaultProduct: ProductType?, _ productStatus: MaintenanceStatus.Product) -> LobbyPageNavigation {
        if defaultProduct == nil {
            return .setDefaultProduct
        } else if !productStatus.isProductMaintain(productType: defaultProduct!) {
            return .playerDefaultProduct(defaultProduct!)
        } else {
            let alternation = alternativeProduct(defaultProduct!, productStatus)
            return .alternativeProduct(defaultProduct!,alternation)
        }
    }
    
    private func alternativeProduct(_ defaultProduct: ProductType,_ productStatus: MaintenanceStatus.Product) -> ProductType {
        return alternativePriority.first { type in
            !productStatus.isProductMaintain(productType: type)
        } ?? ProductType.sbk
    }
    
    func initLoginNavigation(defaultProduct: ProductType?) -> Single<LobbyPageNavigation> {
        return getLoginNeededStatus().map { status in
            switch status {
            case is MaintenanceStatus.AllPortal:
                return .portalAllMaintenance
            case is MaintenanceStatus.Product:
                return self.getLobbyNavigation(defaultProduct, status as! MaintenanceStatus.Product)
            default:
                fatalError("Should not reach here.")
            }
        }
    }
    
    private func getLoginNeededStatus() -> Single<MaintenanceStatus?> {
        return initLocale().andThen(systemStatusUseCase.observePortalMaintenanceState().first())
    }
}
