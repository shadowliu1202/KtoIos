import Foundation
import RxCocoa
import RxSwift
import sharedbu

class MaintenanceViewModel: CollectErrorViewModel {
  private let systemStatusUseCase: ISystemStatusUseCase
  private let authUseCase: AuthenticationUseCase
  
  @Injected private var loading: Loading
  
  private let disposeBag = DisposeBag()
  
  private var loadingTracker: ActivityIndicator { loading.tracker }
  
  private let maintenanceStatus = BehaviorRelay<MaintenanceStatus>(value: .Product(productsAvailable: [], status: [:]))
  
  lazy var portalMaintenanceStatus = maintenanceStatus.compactMap { $0 as? MaintenanceStatus.AllPortal }
    .asDriverOnErrorJustComplete()
  lazy var productMaintenanceStatus = maintenanceStatus.compactMap { $0 as? MaintenanceStatus.Product }
    .asDriverOnErrorJustComplete()
  
  init(
    _ systemStatusUseCase: ISystemStatusUseCase,
    _ authUseCase: AuthenticationUseCase)
  {
    self.systemStatusUseCase = systemStatusUseCase
    self.authUseCase = authUseCase
    
    super.init()
    observeMaintenanceStatusChange()
  }
  
  func observeMaintenanceStatusChange() {
    systemStatusUseCase.observeMaintenanceStatusChange()
      .flatMapLatest { [unowned self] _ in
        systemStatusUseCase.fetchMaintenanceStatus()
          .catch { _ in
            self.maintenanceStatus.accept(.AllPortal(duration: nil))
            return .never()
          }
      }
      .subscribe(onNext: { [maintenanceStatus] in
        maintenanceStatus.accept($0)
      })
      .disposed(by: disposeBag)
  }
  
  @discardableResult
  func pullMaintenanceStatus() async -> MaintenanceStatus {
    do {
      return try await systemStatusUseCase.fetchMaintenanceStatus()
        .do(onSuccess: { [maintenanceStatus] in maintenanceStatus.accept($0) })
        .value
    }
    catch {
      maintenanceStatus.accept(.AllPortal(duration: nil))
      return .AllPortal(duration: nil)
    }
  }
  
  func logout() -> Completable {
    CustomServicePresenter.shared.closeService()
      .concat(authUseCase.logout())
      .trackOnDispose(loadingTracker)
  }
}
