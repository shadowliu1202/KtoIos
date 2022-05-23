import Foundation
import RxSwift
import RxCocoa
import SharedBu

class AppSynchronizeViewModel {
    init(appUpdateUseCase: AppVersionUpdateUseCase) {
        self.appUpdateUseCase = appUpdateUseCase
    }
    private var appUpdateUseCase: AppVersionUpdateUseCase!

    func getLatestAppVersion() -> Single<Version> {
        self.appUpdateUseCase.getLatestAppVersion()
    }
    
    func getSuperSignStatus() -> Single<SuperSignStatus> {
        self.appUpdateUseCase.getSuperSignatureMaintenance()
    }
}
