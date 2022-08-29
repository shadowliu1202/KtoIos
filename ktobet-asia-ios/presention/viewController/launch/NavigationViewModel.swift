import Foundation
import RxSwift
import SharedBu

class NavigationViewModel {
    typealias isLogged = Bool
    
    enum LobbyPageNavigation {
        //TODO: Split Lobby and Launch
        case portalAllMaintenance
        case notLogin
        case playerDefaultProduct(ProductType)
        case alternativeProduct(ProductType, ProductType)
        case setDefaultProduct
    }
    
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
        return getLaunchNeededStatus().map { (status, isLogged, playerSetting) in
            switch status {
            case is MaintenanceStatus.AllPortal:
                return .portalAllMaintenance
            case is MaintenanceStatus.Product:
                return self.getPageNavigation(isLogged, playerSetting, status as! MaintenanceStatus.Product)
            default:
                fatalError("Should not reach here.")
            }
        }
    }
    
    private func getLaunchNeededStatus() -> Single<(MaintenanceStatus?, isLogged, PlayerSetting?)> {
        return initLocale().andThen(Single.zip(systemStatusUseCase.observePortalMaintenanceState().first(), checkIsLogged()))
            .flatMap { (maintenanceStatus, isLogin) in
                if isLogin {
                    return self.getPlayerSetting().map { (maintenanceStatus, isLogin, $0) }
                } else {
                    return Single.just((maintenanceStatus, isLogin, nil))
                }
            }
    }
    
    private func initLocale() -> Completable {
        localizationPolicyUseCase.initLocale()
    }
    
    private func getPlayerSetting() -> Single<PlayerSetting> {
        return playerUseCase.loadPlayer().map({ PlayerSetting(accountLocale: $0.locale(), defaultProduct: $0.defaultProduct) })
    }
   
    private func getPageNavigation(_ isLogged: Bool, _ playerSetting: PlayerSetting?, _ productStatus: MaintenanceStatus.Product) -> LobbyPageNavigation {
        isLogged ? getLobbyNavigation(playerSetting!, productStatus) : .notLogin
    }
    
    func getLobbyNavigation(_ playerSetting: PlayerSetting, _ productStatus: MaintenanceStatus.Product) -> LobbyPageNavigation {
        let alternativeProduct = playerSetting.applyBackupStrategy(maintenanceStatus: productStatus)
        if playerSetting.defaultProduct == ProductType.none {
            return .setDefaultProduct
        } else if playerSetting.defaultProduct != alternativeProduct {
            return .alternativeProduct(playerSetting.defaultProduct!, alternativeProduct!)
        } else {
            return .playerDefaultProduct(playerSetting.defaultProduct!)
        }
    }
    
    func initLoginNavigation(playerSetting: PlayerSetting) -> Single<LobbyPageNavigation> {
        return getLoginNeededStatus().map { status in
            switch status {
            case is MaintenanceStatus.AllPortal:
                return .portalAllMaintenance
            case is MaintenanceStatus.Product:
                return self.getLobbyNavigation(playerSetting, status as! MaintenanceStatus.Product)
            default:
                fatalError("Should not reach here.")
            }
        }
    }
    
    private func getLoginNeededStatus() -> Single<MaintenanceStatus?> {
        return initLocale().andThen(systemStatusUseCase.observePortalMaintenanceState().first())
    }
}
