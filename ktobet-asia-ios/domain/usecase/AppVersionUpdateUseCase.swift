import Foundation
import SharedBu
import RxSwift

protocol AppVersionUpdateUseCase {
    func synchronize() -> Maybe<Version>
}

class AppVersionUpdateUseCaseImpl: AppVersionUpdateUseCase {
    var repo : AppUpdateRepository!
    
    init(_ repo : AppUpdateRepository) {
        self.repo = repo
    }
    
    func synchronize() -> Maybe<Version> {
        return repo.getLatestAppVersion()
    }
}
