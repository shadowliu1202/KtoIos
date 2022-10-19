import UIKit
import SharedBu
import RxSwift

class LandingViewController: APPViewController, VersionUpdateProtocol {
    var appSyncViewModel = DI.resolve(AppSynchronizeViewModel.self)!
    private let playerConfiguration = DI.resolve(PlayerConfiguration.self)!
    lazy var playerTimeZone: Foundation.TimeZone = playerConfiguration.localeTimeZone()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncAppVersionUpdate(versionSyncDisposeBag)
    }
    
    // MARK: VersionUpdateProtocol
    func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus) {
        let action = Bundle.main.currentVersion.getUpdateAction(latestVersion: incoming)
        if action == .compulsoryupdate {
            doCompulsoryUpdateConfirm(incoming, superSignStatus)
        }
    }

    private func doCompulsoryUpdateConfirm(_ incoming: Version, _ superSignStatus: SuperSignStatus) {
        if superSignStatus.isMaintenance, let endTime = superSignStatus.endTime {
            self.alertSuperSignMaintain(endTime)
        } else {
            self.confirmUpdate(incoming.apkLink)
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
    
    func confirmUpdate(_ urlString: String) {
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
}
