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
        case portalAllMaintenance
        case playerDefaultProduct(ProductType)
        case setDefaultProduct
    }
    
    private let playerUseCase : PlayerDataUseCase!
    private let localizationPolicyUseCase: LocalizationPolicyUseCase!
    private let systemStatusUseCase: GetSystemStatusUseCase!
    
    var authUseCase: AuthenticationUseCase!
    var localStorageRepo: LocalStorageRepository
    
    init(_ authUseCase: AuthenticationUseCase,
         _ playerUseCase: PlayerDataUseCase,
         _ localizationPolicyUseCase: LocalizationPolicyUseCase,
         _ systemStatusUseCase: GetSystemStatusUseCase,
         _ localStorageRepo: LocalStorageRepository) {
        self.authUseCase = authUseCase
        self.playerUseCase = playerUseCase
        self.localizationPolicyUseCase = localizationPolicyUseCase
        self.systemStatusUseCase = systemStatusUseCase
        self.localStorageRepo = localStorageRepo
    }
    
    func checkIsLogged() -> Single<isLogged>{
        authUseCase.isLogged()
    }
    
    func initLaunchNavigation() -> LaunchPageNavigation {
        guard let playerInfoCache = localStorageRepo.getPlayerInfo() else { return .Landing }
        let defaultProduct = ProductType.convert(playerInfoCache.defaultProduct)

        if authUseCase.isLastAPISuccessDateExpire() {
            return .Landing
        }
        else {
            return .Lobby(defaultProduct)
        }
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
        if playerSetting.defaultProduct == ProductType.none {
            return .setDefaultProduct
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
