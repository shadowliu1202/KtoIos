import UIKit
import SharedBu
import RxSwift

class LobbyViewController: APPViewController, VersionUpdateProtocol {
    
    private let disposeBag = DisposeBag()
    
    private lazy var playerViewModel = DI.resolve(PlayerViewModel.self)!
    
    lazy var appSyncViewModel = DI.resolve(AppSynchronizeViewModel.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPlayerLoginStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncAppVersionUpdate(versionSyncDisposeBag)
    }

    private func checkPlayerLoginStatus() {
        playerViewModel.checkIsLogged()
            .subscribe { [weak self] isLogged in
                if !isLogged {
                    self?.logoutToLanding()
                }
                
            } onFailure: { [weak self] error in
                if error.isUnauthorized() {
                    self?.logoutToLanding()
                } else {
                    UIApplication.topViewController()?.handleErrors(error)
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func logoutToLanding() {
        CustomServicePresenter.shared.close(completion: { [weak self] in
            guard let self = self else { return }
            
            self.playerViewModel.logout()
                .subscribe(onCompleted: {
                    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
                })
                .disposed(by: self.disposeBag)
        })
    }
    
    // MARK: VersionUpdateProtocol
    func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus) {
        let action = Bundle.main.currentVersion.getUpdateAction(latestVersion: incoming)
        if action == .compulsoryupdate {
            self.executeLogout()
        }
    }
    
    private func executeLogout() {
        playerViewModel.logout().subscribe(on: MainScheduler.instance).subscribe(onCompleted: { [weak self] in
            self?.versionSyncDisposeBag = DisposeBag()
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
        }, onError: {
            print($0)
        }).disposed(by: versionSyncDisposeBag)
    }
}
