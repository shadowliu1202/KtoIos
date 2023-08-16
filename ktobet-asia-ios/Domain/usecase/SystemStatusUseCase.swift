import Foundation
import RxSwift
import SharedBu

protocol ISystemStatusUseCase {
  func fetchOTPStatus() -> Single<OtpStatus>
  func fetchMaintenanceStatus() -> Single<MaintenanceStatus>
  func fetchCustomerServiceEmail() -> Single<String>
  func fetchCopyRight() -> Single<String>
  
  func observeMaintenanceStatusByFetch() -> Observable<MaintenanceStatus>
  func refreshMaintenanceState()
  
  func observeMaintenanceStatusChange() -> Observable<Void>
  func observePlayerBalanceChange() -> Observable<Void>
  func observeKickOutSignal() -> RxSwift.Observable<KickOutSignal>
}

class SystemStatusUseCase: ISystemStatusUseCase {
  private let systemRepository: SystemRepository
  private let signalRepository: SignalRepository

  init(
    _ systemRepository: SystemRepository,
    _ signalRepository: SignalRepository)
  {
    self.systemRepository = systemRepository
    self.signalRepository = signalRepository
  }

  func fetchOTPStatus() -> Single<OtpStatus> {
    systemRepository.fetchOTPStatus()
  }

  func observeMaintenanceStatusByFetch() -> Observable<MaintenanceStatus> {
    systemRepository.observePortalMaintenanceState()
  }

  func fetchMaintenanceStatus() -> Single<MaintenanceStatus> {
    systemRepository.fetchMaintenanceStatus()
  }

  func fetchCustomerServiceEmail() -> Single<String> {
    systemRepository.fetchCustomerServiceEmail()
  }

  func refreshMaintenanceState() {
    systemRepository.refreshPortalMaintenanceState()
  }

  func fetchCopyRight() -> Single<String> {
    systemRepository.fetchCopyRight()
  }

  func observeMaintenanceStatusChange() -> RxSwift.Observable<Void> {
    signalRepository
      .observeSystemSignal()
      .filter { $0 is MaintenanceSignal }
      .map { _ in () }
  }

  func observePlayerBalanceChange() -> Observable<Void> {
    signalRepository
      .observeSystemSignal()
      .filter { $0 is BalanceSignal }
      .map { _ in () }
  }
  
  func observeKickOutSignal() -> RxSwift.Observable<KickOutSignal> {
    signalRepository
      .observeSystemSignal()
      .compactMap { $0 as? KickOutSignal }
  }
}
