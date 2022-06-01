import Foundation
import SharedBu
import RxSwift

protocol AppVersionUpdateUseCase {
    func getLatestAppVersion() -> Single<Version>
    func getSuperSignatureMaintenance() -> Single<SuperSignStatus>
}

class AppVersionUpdateUseCaseImpl: AppVersionUpdateUseCase {
    var repo : AppUpdateRepository!
    var playerConf: PlayerConfiguration!
    private var timezone: Foundation.TimeZone!
    
    init(_ repo : AppUpdateRepository, _ playerConfiguration: PlayerConfiguration) {
        self.repo = repo
        self.playerConf = playerConfiguration
        self.timezone = self.playerConf.localeTimeZone()

    }
    
    func getLatestAppVersion() -> Single<Version> {
        repo.getLatestAppVersion()
    }
    
    func getSuperSignatureMaintenance() -> Single<SuperSignStatus> {
        repo.getSuperSignatureMaintenance().map({ SuperSignStatus(bean: $0, timezone: self.timezone) })
    }
}
