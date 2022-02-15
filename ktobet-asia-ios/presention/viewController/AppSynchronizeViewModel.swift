import Foundation
import RxSwift
import RxCocoa
import SharedBu

class AppSynchronizeViewModel {
    static let shared = AppSynchronizeViewModel()
    private init() {
        self.appUpdateUseCase = DI.resolve(AppVersionUpdateUseCase.self)!
    }
    private var appUpdateUseCase: AppVersionUpdateUseCase!
    var compulsoryupdate = BehaviorRelay<Version?>(value: nil)
    var optionalupdate = BehaviorRelay<Version?>(value: nil)
    var uptodate = BehaviorRelay<Version.VersionState?>(value: nil)
    lazy var synchronize = self.appUpdateUseCase.synchronize()
    func getCurrentVersion() -> Version {
        Version.companion.create(version: Bundle.main.releaseVersionNumber)
    }
    
    func syncAppVersion() {
        guard Configuration.isAutoUpdate else { return }
        let current = getCurrentVersion()
        let _ = appUpdateUseCase.synchronize().subscribe(onSuccess: { [unowned self] in
            let state = $0.getVersionState(currentVersion: current)
            switch state {
            case .compulsoryupdate:
                self.compulsoryupdate.accept($0)
            case .optionalupdate:
                self.optionalupdate.accept($0)
            case .uptodate:
                self.uptodate.accept(state)
            default:
                self.uptodate.accept(state)
            }
        })
    }
}
