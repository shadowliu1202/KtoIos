import Foundation
import RxCocoa
import RxSwift
import SharedBu

class MaintenanceViewModel: CollectErrorViewModel {
  @Injected private var systemStatusUseCase: ISystemStatusUseCase
  @Injected private var authUseCase: AuthenticationUseCase
  
  @Injected private var loading: Loading

  private let maintenanceStatusTrigger = BehaviorRelay(value: ())
  private let disposeBag = DisposeBag()
  
  private var loadingTracker: ActivityIndicator { loading.tracker }
  
  private lazy var maintenanceStatus = observeMaintenanceStatus()
  
  lazy var portalMaintenanceStatus = maintenanceStatus.compactMap { $0 as? MaintenanceStatus.AllPortal }
  lazy var productMaintenanceStatus = maintenanceStatus.compactMap { $0 as? MaintenanceStatus.Product }

  func observeMaintenanceStatus() -> Driver<MaintenanceStatus> {
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
  
  func refreshStatus() {
    maintenanceStatusTrigger.accept(())
  }
  
  func logout() -> Completable {
    CustomServicePresenter.shared.closeService()
      .concat(authUseCase.logout())
      .trackOnDispose(loadingTracker)
  }
}
