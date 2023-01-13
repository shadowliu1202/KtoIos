import UIKit
import SharedBu
import RxSwift

class LobbyViewController: APPViewController, VersionUpdateProtocol {
    
    private let disposeBag = DisposeBag()
    
    private var viewDisappearBag = DisposeBag()
    
    private lazy var playerViewModel = Injectable.resolve(PlayerViewModel.self)!
    
    lazy var appSyncViewModel = Injectable.resolve(AppSynchronizeViewModel.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPlayerLoginStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncAppVersionUpdate(viewDisappearBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewDisappearBag = DisposeBag()
    }
    
    override func networkReConnectedHandler() {
        super.networkReConnectedHandler()
        checkPlayerLoginStatus()
    }

    private func checkPlayerLoginStatus() {
        playerViewModel
            .checkIsLogged()
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
        playerViewModel
            .logout()
            .subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
            })
            .disposed(by: self.disposeBag)
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
            self?.viewDisappearBag = DisposeBag()
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
        }, onError: {
            print($0)
        }).disposed(by: viewDisappearBag)
    }
}
