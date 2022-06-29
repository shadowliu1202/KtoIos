import UIKit
import SharedBu
import RxSwift

protocol VersionUpdateProtocol  {
    var appSyncViewModel: AppSynchronizeViewModel { get }
    func syncAppVersionUpdate(_ disposeBag: DisposeBag)
    func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus)
}

extension VersionUpdateProtocol where Self: APPViewController {
    func syncAppVersionUpdate(_ disposeBag: DisposeBag) {
        syncAppVersion(disposeBag)
        registerAppEnterForeground(disposeBag)
    }
    
    private func syncAppVersion(_ disposeBag: DisposeBag) {
        Observable.combineLatest(appSyncViewModel.getLatestAppVersion().asObservable(), appSyncViewModel.getSuperSignStatus().asObservable())
            .subscribe(onNext: { [weak self] (incoming, superSignStatus) in
                guard Configuration.isAutoUpdate else { return }
                self?.updateStrategy(incoming, superSignStatus)
            }).disposed(by: disposeBag)
    }
    
    private func registerAppEnterForeground(_ disposeBag: DisposeBag) {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification).takeUntil(self.rx.deallocated).subscribe(onNext: { [weak self] _ in
            self?.syncAppVersion(disposeBag)
        }).disposed(by: disposeBag)
    }
    
}
