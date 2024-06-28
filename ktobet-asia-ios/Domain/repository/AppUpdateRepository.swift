import Foundation
import RxSwift
import sharedbu

protocol AppUpdateRepository {
    func getLatestAppVersion() -> Single<OnlineVersion>
    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean>
}

class AppUpdateRepositoryImpl: AppUpdateRepository {
    private var versionUpdateApi: VersionUpdateApi!

    init(_ updateApi: VersionUpdateApi) {
        self.versionUpdateApi = updateApi
    }

    func getLatestAppVersion() -> Single<OnlineVersion> {
        versionUpdateApi.getIOSVersion().map({ $0.toVersion() })
    }

    func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean> {
        versionUpdateApi.getSuperSignatureMaintenance()
    }
}
