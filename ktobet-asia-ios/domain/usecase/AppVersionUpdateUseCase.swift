import Foundation
import RxSwift
import SharedBu

protocol AppVersionUpdateUseCase {
  func getLatestAppVersion() -> Single<Version>
  func getSuperSignatureMaintenance() -> Single<SuperSignStatus>
}

class AppVersionUpdateUseCaseImpl: AppVersionUpdateUseCase {
  var repo: AppUpdateRepository!
  var localStorageRepo: LocalStorageRepository!
  private var timezone: Foundation.TimeZone!

  init(_ repo: AppUpdateRepository, _ localStorageRepo: LocalStorageRepository) {
    self.repo = repo
    self.localStorageRepo = localStorageRepo
    self.timezone = self.localStorageRepo.localeTimeZone()
  }

  func getLatestAppVersion() -> Single<Version> {
    repo.getLatestAppVersion()
  }

  func getSuperSignatureMaintenance() -> Single<SuperSignStatus> {
    repo.getSuperSignatureMaintenance().map({ SuperSignStatus(bean: $0, timezone: self.timezone) })
  }
}
