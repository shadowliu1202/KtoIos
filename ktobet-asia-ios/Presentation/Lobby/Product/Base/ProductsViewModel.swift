import Foundation
import RxCocoa
import RxSwift
import SharedBu

class ProductsViewModel: CollectErrorViewModel {
  @Injected private var systemStatusUseCase: ISystemStatusUseCase
  @Injected private var authUseCase: AuthenticationUseCase
  
  @Injected private var loading: Loading

  private let maintenanceStatusTrigger = BehaviorRelay(value: ())
  private let disposeBag = DisposeBag()
  
  private var loadingTracker: ActivityIndicator { loading.tracker }
  
  lazy var maintenanceStatus = observeMaintenanceStatus()

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
  
  func refreshMaintenanceStatus() {
    maintenanceStatusTrigger.accept(())
  }
  
  func logout() -> Completable {
    CustomServicePresenter.shared.closeService()
      .observe(on: MainScheduler.instance)
      .concat(authUseCase.logout())
      .trackOnDispose(loadingTracker)
  }
}
