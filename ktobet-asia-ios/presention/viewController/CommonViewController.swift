import UIKit
import RxSwift
import SharedBu

class CommonViewController: APPViewController, VersionUpdateProtocol {
    private let playerViewModel = DI.resolve(PlayerViewModel.self)!
    var appSyncViewModel = DI.resolve(AppSynchronizeViewModel.self)!
    private let playerConfiguration = DI.resolve(PlayerConfiguration.self)!
    private lazy var playerTimeZone: Foundation.TimeZone = playerConfiguration.localeTimeZone()
    private var disposeBag = DisposeBag()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncAppVersionUpdate(versionSyncDisposeBag)
    }
    
    // MARK: VersionUpdateProtocol
    func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus) {
        let action = Bundle.main.currentVersion.getUpdateAction(latestVersion: incoming)
        if action == .compulsoryupdate {
            playerViewModel.checkIsLogged().subscribe(onSuccess: { [weak self] isLogin in
                guard isLogin == false else {
                    self?.executeLogout()
                    return
                }
                if superSignStatus.isMaintenance, let endTime = superSignStatus.endTime {
                    self?.alertSuperSignMaintain(endTime)
                } else {
                    self?.confirmUpdate(incoming.apkLink)
                }
            }, onError: { [weak self] in
                self?.handleErrors($0)
            }).disposed(by: versionSyncDisposeBag)
        }
    }
    
    private func alertSuperSignMaintain(_ endTime: Date) {
        guard !Alert.shared.isShown() else { return }
        let endTimeStr = convertDateString(endTime)
        Alert.shared.show(Localize.string("common_tip_title_warm"), Localize.string("common_super_signature_maintenance", endTimeStr), confirm: {
            exit(0)
        }, cancel: nil)
    }
    
    private func convertDateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = playerTimeZone
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    private func confirmUpdate(_ urlString: String) {
        guard !Alert.shared.isShown() else { return }
        Alert.shared.show(nil,
                   Localize.string("update_new_version_content"),
                   confirm: {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        },
                   confirmText: Localize.string("update_proceed_now"),
                   cancel: {
            exit(0)
        },
                   cancelText: Localize.string("update_exit"))
    }
    
    private func executeLogout() {
        playerViewModel.logout().subscribeOn(MainScheduler.instance).subscribe(onCompleted: { [weak self] in
            self?.disposeBag = DisposeBag()
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
        }, onError: {
            print($0)
        }).disposed(by: disposeBag)
    }
}
