import Foundation
import RxSwift
import SharedBu

protocol AppUpdateRepository {
    func getLatestAppVersion() -> Single<Version>
    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean>
}

class AppUpdateRepositoryImpl: AppUpdateRepository {
    private var portalApi : PortalApi!
    
    init(_ portalApi : PortalApi) {
        self.portalApi = portalApi
    }
    
    func getLatestAppVersion() -> Single<Version> {
        portalApi.getIOSVersion().map({ $0.data.toVersion() })
    }
    
    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean> {
        portalApi.getSuperSignatureMaintenance()
    }
}
