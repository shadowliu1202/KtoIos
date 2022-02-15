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
        appSyncDispose = AppSynchronizeViewModel.shared.compulsoryupdate.compactMap({$0}).subscribe(onNext: { [weak self] in
            self?.confirmUpdate($0.apkLink)
        })
    }
    
    func observerUpdates() {
        appSyncDispose = Observable.merge(AppSynchronizeViewModel.shared.optionalupdate.compactMap({$0}), AppSynchronizeViewModel.shared.compulsoryupdate.compactMap({$0})).subscribe(onNext: { [weak self] in
            self?.confirmUpdate($0.apkLink)
        })
    }
    
    func confirmUpdate(_ urlString: String) {
        guard !isAlertShown else { return }
        isAlertShown = true
        Alert.show(nil,
                   Localize.string("update_new_version_content"),
                   confirm: { [weak self] in
            self?.isAlertShown = false
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
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
