import Foundation
import RxSwift
import SharedBu

class NavigationViewModel {
    typealias isLogged = Bool
    
    enum LaunchPageNavigation {
        case Landing
        case Lobby(ProductType)
    }
    
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
    private let localStorageRepo: LocalStorageRepositoryImpl
    
    init(_ authUseCase: AuthenticationUseCase,
         _ playerUseCase: PlayerDataUseCase,
         _ localizationPolicyUseCase: LocalizationPolicyUseCase,
         _ systemStatusUseCase: GetSystemStatusUseCase,
         _ localStorageRepo: LocalStorageRepositoryImpl) {
        self.authUseCase = authUseCase
        self.playerUseCase = playerUseCase
        self.localizationPolicyUseCase = localizationPolicyUseCase
        self.systemStatusUseCase = systemStatusUseCase
        self.localStorageRepo = localStorageRepo
    }
    
    func checkIsLogged() -> Single<isLogged>{
        authUseCase.isLogged()
    }
    
    func initLaunchNavigation() -> Single<LaunchPageNavigation> {
        guard let playerInfoCache = localStorageRepo.getPlayerInfo() else { return .just(.Landing) }
        let defaultProduct = ProductType.convert(playerInfoCache.defaultProduct)

        return Single.just(authUseCase.IsLastAPISuccessDateExpire() ? .Landing : .Lobby(defaultProduct))
    }
    
    func initLoginNavigation(playerSetting: PlayerSetting) -> Single<LobbyPageNavigation> {
        return getLoginNeededStatus().map { status in
            switch status {
            case is MaintenanceStatus.AllPortal:
                return .portalAllMaintenance
            case is MaintenanceStatus.Product:
                if playerSetting.defaultProduct == ProductType.none {
                    return .setDefaultProduct
                } else {
                    return .playerDefaultProduct(playerSetting.defaultProduct!)
                }
            default:
                fatalError("Should not reach here.")
            }
        }
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
    
    private func getLoginNeededStatus() -> Single<MaintenanceStatus?> {
        return initLocale().andThen(systemStatusUseCase.observePortalMaintenanceState().first())
    }
    
    private func initLocale() -> Completable {
        localizationPolicyUseCase.initLocale()
    }
}
