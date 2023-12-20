import Foundation
import RxCocoa
import RxSwift
import sharedbu

class SideMenuViewModel: CollectErrorViewModel {
  @Injected private var systemStatusUseCase: ISystemStatusUseCase
  @Injected private var playerDataUseCase: PlayerDataUseCase
  @Injected private var authenticationUseCase: AuthenticationUseCase
  @Injected private var playerConfiguration: PlayerConfiguration

  @Injected private var loading: Loading

  private let playerInfoTrigger = BehaviorRelay(value: ())
  private let playerBalanceTrigger = BehaviorRelay(value: ())

  private let disposeBag = DisposeBag()
  
  private var loadingTracker: ActivityIndicator { loading.tracker }

  lazy var playerInfo = observePlayerInfo()
  lazy var playerBalance = observePlayerBalance()
  
  // MARK: - PlayerInfo
  
  func observePlayerInfo() -> Driver<PlayerInfoDTO> {
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
  
  func observePlayerBalance() -> Driver<AccountCurrency> {
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
  
  // MARK: - KickOutSignal
  
  func observeKickOutSignal() -> RxSwift.Observable<KickOutSignal> {
    systemStatusUseCase.observeKickOutSignal()
  }

  func refreshData() {
    refreshPlayerInfo()
    refreshPlayerBalance()
  }
  
  func loadBalanceHiddenState(by gamerID: String) -> Bool {
    playerDataUseCase.getBalanceHiddenState(gameId: gamerID)
  }

  func saveBalanceHiddenState(gamerID: String, isHidden: Bool) {
    playerDataUseCase.setBalanceHiddenState(gameId: gamerID, isHidden: isHidden)
  }
  
  func getSupportLoacle() -> SupportLocale {
    playerConfiguration.supportLocale
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
