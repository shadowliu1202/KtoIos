import UIKit
import SharedBu
import RxSwift

class LobbyViewController: APPViewController, VersionUpdateProtocol {
    private let playerViewModel = DI.resolve(PlayerViewModel.self)!
    var appSyncViewModel = DI.resolve(AppSynchronizeViewModel.self)!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncAppVersionUpdate(versionSyncDisposeBag)
    }
    
    // MARK: VersionUpdateProtocol
    func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus) {
        let action = Bundle.main.currentVersion.getUpdateAction(latestVersion: incoming)
        if action == .compulsoryupdate {
            self.executeLogout()
        }
    }
    
    private func executeLogout() {
        playerViewModel.logout().subscribeOn(MainScheduler.instance).subscribe(onCompleted: { [weak self] in
            self?.versionSyncDisposeBag = DisposeBag()
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }, onError: {
            print($0)
        }).disposed(by: versionSyncDisposeBag)
    }
}
