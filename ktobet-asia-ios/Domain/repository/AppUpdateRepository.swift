import Foundation
import RxSwift
import SharedBu

protocol AppUpdateRepository {
  func getLatestAppVersion() -> Single<Version>
  func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean>
}

class AppUpdateRepositoryImpl: AppUpdateRepository {
  private var versionUpdateApi: VersionUpdateApi!

  init(_ updateApi: VersionUpdateApi) {
    self.versionUpdateApi = updateApi
  }

  func getLatestAppVersion() -> Single<Version> {
    versionUpdateApi.getIOSVersion().map({ $0.data.toVersion() })
  }

  func getSuperSignatureMaintenance() -> Single<SuperSignMaintenanceBean> {
    versionUpdateApi.getSuperSignatureMaintenance()
  }
}
