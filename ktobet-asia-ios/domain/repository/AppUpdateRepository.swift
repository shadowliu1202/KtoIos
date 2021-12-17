import Foundation
import RxSwift
import SharedBu

protocol AppUpdateRepository {
    func getLatestAppVersion() -> Maybe<Version>
}

class AppUpdateRepositoryImpl: AppUpdateRepository {
    private var portalApi : PortalApi!
    
    init(_ portalApi : PortalApi) {
        self.portalApi = portalApi
    }
    
    func getLatestAppVersion() -> Maybe<Version> {
        portalApi.getIOSVersion().compactMap({$0.data}).map({ $0.toVersion() })
    }
}
