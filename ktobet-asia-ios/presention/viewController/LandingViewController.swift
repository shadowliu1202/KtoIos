import UIKit
import RxSwift

class LandingViewController: APPViewController {
    private var isAlertShown = false
    private var appSyncDispose: Disposable?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        abstracObserverUpdate()
        AppSynchronizeViewModel.shared.syncAppVersion()
    }
    
    func abstracObserverUpdate() {
        fatalError("Subclasses must override.")
    }
    
    func observerCompulsoryUpdate() {
        appSyncDispose = AppSynchronizeViewModel.shared.compulsoryupdate.compactMap({$0}).subscribe(onNext: { [weak self] _ in
            self?.confirmUpdate()
        })
    }
    
    func observerUpdates() {
        appSyncDispose = Observable.merge(AppSynchronizeViewModel.shared.optionalupdate.compactMap({$0}), AppSynchronizeViewModel.shared.compulsoryupdate.compactMap({$0})).subscribe(onNext: { [weak self] _ in
            self?.confirmUpdate()
        })
    }
    
    func confirmUpdate() {
        guard !isAlertShown else { return }
        isAlertShown = true
        Alert.show(nil,
                   Localize.string("update_new_version_content"),
                   confirm: { [weak self] in
            self?.isAlertShown = false
            if UIApplication.shared.canOpenURL(Configuration.downloadUrl) {
                UIApplication.shared.open(Configuration.downloadUrl)
            }
        },
                   confirmText: Localize.string("update_proceed_now"),
                   cancel: { [weak self] in
            self?.isAlertShown = false
            exit(0)
        },
                   cancelText: Localize.string("update_exit"))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appSyncDispose?.dispose()
    }
}
