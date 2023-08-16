import Foundation
import RxCocoa
import RxSwift
import SharedBu

class SideMenuViewModel: CollectErrorViewModel {
  @Injected private var systemStatusUseCase: ISystemStatusUseCase
  @Injected private var playerDataUseCase: PlayerDataUseCase
  @Injected private var authenticationUseCase: AuthenticationUseCase
  @Injected private var localStorageRepo: LocalStorageRepository

  @Injected private var loading: Loading
  
  private let products = {
    let titles = [
      Localize.string("common_sportsbook"),
      Localize.string("common_casino"),
      Localize.string("common_slot"),
      Localize.string("common_keno"),
      Localize.string("common_p2p"),
      Localize.string("common_arcade")
    ]

    let imgs = ["SBK", "Casino", "Slot", "Number Game", "P2P", "Arcade"]
    let types: [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]

    return zip(titles, zip(imgs, types))
      .map { title, imgAndType in
        let (image, type) = imgAndType
        return ProductItem(title: title, image: image, type: type)
      }
  }()

  private let playerInfoTrigger = BehaviorRelay(value: ())
  private let playerBalanceTrigger = BehaviorRelay(value: ())
  private let maintenanceStatusTrigger = BehaviorRelay(value: ())

  private let disposeBag = DisposeBag()
  
  private var loadingTracker: ActivityIndicator { loading.tracker }

  lazy var playerInfo = observePlayerInfo()
  lazy var playerBalance = observePlayerBalance()
  lazy var productsStatus = observeProductsStatus()
  lazy var maintenanceStatus = observeMaintenanceStatus()
  
  // MARK: - PlayerInfo
  
  private func observePlayerInfo() -> Driver<PlayerInfoDTO> {
    playerInfoTrigger
      .flatMapLatest { [weak self, playerDataUseCase] _ in
        playerDataUseCase.fetchPlayer()
          .catch {
            self?.errorsSubject.onNext($0)
            return .never()
          }
      }
      .asDriverOnErrorJustComplete()
  }

  private func refreshPlayerInfo() {
    playerInfoTrigger.accept(())
  }
  
  // MARK: - PlayerBalance
  
  private func observePlayerBalance() -> Driver<AccountCurrency> {
    Observable.merge(
      playerBalanceTrigger.asObservable(),
      systemStatusUseCase.observePlayerBalanceChange())
      .flatMapLatest { [weak self, playerDataUseCase] _ in
        playerDataUseCase.getBalance()
          .catch {
            self?.errorsSubject.onNext($0)
            return .never()
          }
      }
      .asDriverOnErrorJustComplete()
  }
  
  func refreshPlayerBalance() {
    playerBalanceTrigger.accept(())
  }
  
  // MARK: - ProductsStatus
  
  private func observeProductsStatus() -> Driver<[ProductItem]> {
    maintenanceStatus
      .compactMap { [products] status -> [ProductItem]? in
        guard let status = status as? MaintenanceStatus.Product
        else { return nil }
        
        return products
          .map { $0.updateMaintainTime(status.getMaintenanceTime(productType: $0.type)) }
      }
  }

  // MARK: - MaintenanceStatus
  
  private func observeMaintenanceStatus() -> Driver<MaintenanceStatus> {
    Observable.merge(
      maintenanceStatusTrigger.asObservable(),
      systemStatusUseCase.observeMaintenanceStatusChange())
      .flatMapLatest { [weak self, systemStatusUseCase] _ in
        systemStatusUseCase.fetchMaintenanceStatus()
          .catch {
            self?.errorsSubject.onNext($0)
            return .never()
          }
      }
      .asDriverOnErrorJustComplete()
  }
  
  func refreshMaintenanceStatus() {
    maintenanceStatusTrigger.accept(())
  }
  
  // MARK: - KickOutSignal
  
  func observeKickOutSignal() -> RxSwift.Observable<KickOutSignal> {
    systemStatusUseCase.observeKickOutSignal()
  }

  func refreshData() {
    refreshPlayerInfo()
    refreshPlayerBalance()
    refreshMaintenanceStatus()
  }
  
  func loadBalanceHiddenState(by gamerID: String) -> Bool {
    playerDataUseCase.getBalanceHiddenState(gameId: gamerID)
  }

  func saveBalanceHiddenState(gamerID: String, isHidden: Bool) {
    playerDataUseCase.setBalanceHiddenState(gameId: gamerID, isHidden: isHidden)
  }
  
  func getCultureCode() -> String {
    localStorageRepo.getCultureCode()
  }
  
  func logout() -> Completable {
    CustomServicePresenter.shared.closeService()
      .observe(on: MainScheduler.instance)
      .concat(authenticationUseCase.logout())
      .trackOnDispose(loadingTracker)
  }
}

struct ProductItem {
  var title = ""
  var image = ""
  var type = ProductType.none
  var maintainTime: OffsetDateTime?
  
  func updateMaintainTime(_ time: OffsetDateTime?) -> Self {
    .init(title: title, image: image, type: type, maintainTime: time)
  }
}

struct FeatureItem {
  var type: FeatureType
  var name: String
  var icon: String
}
