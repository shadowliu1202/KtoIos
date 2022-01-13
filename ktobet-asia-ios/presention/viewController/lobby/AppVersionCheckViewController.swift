import UIKit
import RxSwift

class AppVersionCheckViewController: APPViewController {
    private var appSyncDispose: Disposable?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observerCompulsoryUpdate()
    }
    
    func observerCompulsoryUpdate() {
        let playerViewModel = DI.resolve(PlayerViewModel.self)!
        appSyncDispose = AppSynchronizeViewModel.shared.compulsoryupdate.compactMap({$0}).subscribe(onNext: { _ in
            let _ = playerViewModel.logout().subscribeOn(MainScheduler.instance).subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
            }, onError: {
                print($0)
            })
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appSyncDispose?.dispose()
    }
}

extension AppVersionCheckViewController: WebGameViewCallback {
    func gameDidDisappear() {
        if Reachability?.isNetworkConnected == false {
            self.networkDisConnected()
        }
        AppSynchronizeViewModel.shared.syncAppVersion()
    }
}
