import Foundation
import RxSwift
import sharedbu

protocol AppVersionUpdateUseCase {
  func getLatestAppVersion() -> Single<sharedbu.Version>
  func getSuperSignatureMaintenance() -> Single<SuperSignStatus>
}

class AppVersionUpdateUseCaseImpl: AppVersionUpdateUseCase {
  private let repo: AppUpdateRepository
  private let playerConfiguration: PlayerConfiguration
  private let timezone: Foundation.TimeZone

  init(_ repo: AppUpdateRepository, _ playerConfiguration: PlayerConfiguration) {
    self.repo = repo
    self.playerConfiguration = playerConfiguration
    self.timezone = playerConfiguration.localeTimeZone()
  }

  func getLatestAppVersion() -> Single<sharedbu.Version> {
    repo.getLatestAppVersion()
  }

  func getSuperSignatureMaintenance() -> Single<SuperSignStatus> {
    repo.getSuperSignatureMaintenance().map({ SuperSignStatus(bean: $0, timezone: self.timezone) })
  }
}
