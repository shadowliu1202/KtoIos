import Foundation
import RxCocoa
import RxSwift
import sharedbu

class AppSynchronizeViewModel {
    private let appUpdateUseCase: AppVersionUpdateUseCase
    private let appStorage: ApplicationStorable

    init(
        appUpdateUseCase: AppVersionUpdateUseCase,
        appStorage: ApplicationStorable)
    {
        self.appUpdateUseCase = appUpdateUseCase
        self.appStorage = appStorage
    }

    func getLatestAppVersion() -> Single<sharedbu.Version> {
        self.appUpdateUseCase.getLatestAppVersion()
    }

    func getSuperSignStatus() -> Single<SuperSignStatus> {
        self.appUpdateUseCase.getSuperSignatureMaintenance()
    }

    func getIsPoppedAutoUpdate() -> Bool {
        appStorage.getIsPoppedAutoUpdate()
    }

    func setIsPoppedAutoUpdate(_ popped: Bool) {
        appStorage.setIsPoppedAutoUpdate(popped)
    }
}
