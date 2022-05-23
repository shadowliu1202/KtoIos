import UIKit
import RxSwift
import SharedBu

class LandingViewController: APPViewController {
    private var isAlertShown = false
    private let appSyncViewModel = DI.resolve(AppSynchronizeViewModel.self)!
    private var disposeBag: DisposeBag!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disposeBag = DisposeBag()
        syncAppVersionUpdate()
        registerAppEnterForeground()
    }
    
    func registerAppEnterForeground() {
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification).takeUntil(self.rx.deallocated).subscribe(onNext: { [weak self] _ in
            self?.syncAppVersionUpdate()
        }).disposed(by: disposeBag)
    }
    
    func syncAppVersionUpdate() {
        guard Configuration.isAutoUpdate else { return }
        Observable.combineLatest(appSyncViewModel.getLatestAppVersion().asObservable(), appSyncViewModel.getSuperSignStatus().asObservable())
            .subscribe(onNext: { [weak self] (incoming, superSignStatus) in
                self?.updateStrategy(incoming, superSignStatus)
            }).disposed(by: disposeBag)
    }
    
    func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus?) {
        let action = Bundle.main.currentVersion.getUpdateAction(latestVersion: incoming)
        if action == .compulsoryupdate {
            doCompulsoryUpdateConfirm(incoming, superSignStatus)
        }
    }
    
    private func doCompulsoryUpdateConfirm(_ incoming: Version,_ superSignStatus: SuperSignStatus?) {
        if  let isMaintenance = superSignStatus?.isMaintenance, isMaintenance == true,
            let endTime = superSignStatus?.endTime {
            alertSuperSignMaintain(convertDateString(endTime))
        } else {
            confirmUpdate(incoming.apkLink)
        }
    }
    
    private func convertDateString(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Date().playerTimeZone
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    private func alertSuperSignMaintain(_ endTime: String) {
        guard !isAlertShown else { return }
        isAlertShown = true
        Alert.show(Localize.string("common_tip_title_warm") , Localize.string("common_super_signature_maintenance", endTime), confirm: { [weak self] in
            self?.isAlertShown = false
            exit(0)
        }, cancel: nil)
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
        disposeBag = DisposeBag()
    }
}
