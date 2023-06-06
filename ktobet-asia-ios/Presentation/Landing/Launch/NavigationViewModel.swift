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

  private let playerUseCase: PlayerDataUseCase!
  private let localizationPolicyUseCase: LocalizationPolicyUseCase!
  private let systemStatusUseCase: GetSystemStatusUseCase!
  private let authUseCase: AuthenticationUseCase!
  private let localStorageRepo: LocalStorageRepository

  private let checkIsLoggedTracker = ActivityIndicator()

  var isCheckingLogged: Bool {
    checkIsLoggedTracker.isLoading
  }

  init(
    _ authUseCase: AuthenticationUseCase,
    _ playerUseCase: PlayerDataUseCase,
    _ localizationPolicyUseCase: LocalizationPolicyUseCase,
    _ systemStatusUseCase: GetSystemStatusUseCase,
    _ localStorageRepo: LocalStorageRepository)
  {
    self.authUseCase = authUseCase
    self.playerUseCase = playerUseCase
    self.localizationPolicyUseCase = localizationPolicyUseCase
    self.systemStatusUseCase = systemStatusUseCase
    self.localStorageRepo = localStorageRepo
  }

  func checkIsLogged() -> Single<isLogged> {
    authUseCase
      .isLogged()
      .trackOnDispose(checkIsLoggedTracker)
  }

  func initLaunchNavigation() -> LaunchPageNavigation {
    guard let playerInfoCache = localStorageRepo.getPlayerInfo() else { return .Landing }
    let defaultProduct = ProductType.convert(playerInfoCache.defaultProduct)

    if authUseCase.isLastAPISuccessDateExpire() {
      localStorageRepo.setPlayerInfo(nil)
      return .Landing
    }
    else {
      return .Lobby(defaultProduct)
    }
  }

  func initLoginNavigation(playerSetting: PlayerSetting) -> Single<LobbyPageNavigation> {
    getLoginNeededStatus().map { status in
      switch status {
      case is MaintenanceStatus.AllPortal:
        return .portalAllMaintenance
      case is MaintenanceStatus.Product:
        if playerSetting.defaultProduct == ProductType.none {
          return .setDefaultProduct
        }
        else {
          return .playerDefaultProduct(playerSetting.defaultProduct!)
        }
      default:
        fatalError("Should not reach here.")
      }
    }
  }

  func getLobbyNavigation(_ playerSetting: PlayerSetting, _: MaintenanceStatus.Product) -> LobbyPageNavigation {
    if playerSetting.defaultProduct == ProductType.none {
      return .setDefaultProduct
    }
    else {
      return .playerDefaultProduct(playerSetting.defaultProduct!)
    }
  }

  private func getLoginNeededStatus() -> Single<MaintenanceStatus?> {
    initLocale().andThen(systemStatusUseCase.observePortalMaintenanceState().first())
  }

  private func initLocale() -> Completable {
    localizationPolicyUseCase.initLocale()
  }
}
