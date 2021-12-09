import Foundation
import RxSwift


class ServiceStatusViewModel {
    private var usecaseSystemStatus : GetSystemStatusUseCase!
    
    init(usecaseSystemStatus :GetSystemStatusUseCase) {
        self.usecaseSystemStatus = usecaseSystemStatus
    }
    
    func getOtpService() -> Single<OtpStatus> {
        return self.usecaseSystemStatus.getOtpStatus()
    }
    
    lazy var portalMaintenanceStatus = usecaseSystemStatus.observePortalMaintenanceState()
}
