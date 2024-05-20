import RxSwift
import sharedbu
import UIKit

struct VersionUpdateInfo {
    let version: Version
    let superSignStatus: SuperSignStatus
    let action: Version.UpdateAction

    var link: String {
        version.apkLink
    }

    init(
        version: Version,
        superSignStatus: SuperSignStatus)
    {
        self.version = version
        self.superSignStatus = superSignStatus
        self.action = Bundle.main.currentVersion.getUpdateAction(latestVersion: version)
    }
}

protocol VersionUpdateProtocol {
    var appSyncViewModel: AppSynchronizeViewModel { get }

    var localTimeZone: Foundation.TimeZone { get }

    func syncAppVersionUpdate(_ disposeBag: DisposeBag)

    func updateStrategy(from info: VersionUpdateInfo)
}

// MARK: - Sync Action

extension VersionUpdateProtocol where Self: APPViewController {
    func syncAppVersionUpdate(_ disposeBag: DisposeBag) {
        syncAppVersion(disposeBag: disposeBag)
        registerAppEnterForeground(disposeBag)
    }

    private func syncAppVersion(disposeBag: DisposeBag) {
        Single.zip(
            appSyncViewModel.getLatestAppVersion(),
            appSyncViewModel.getSuperSignStatus())
            .filter { _ in Configuration.isAutoUpdate }
            .map { version, superSignStatus in
                VersionUpdateInfo(
                    version: version,
                    superSignStatus: superSignStatus)
            }
            .subscribe(onSuccess: { [weak self] info in
                self?.updateStrategy(from: info)
            })
            .disposed(by: disposeBag)
    }

    private func registerAppEnterForeground(_ disposeBag: DisposeBag) {
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .take(until: self.rx.deallocated)
            .subscribe(onNext: { [weak self] _ in
                self?.syncAppVersion(disposeBag: disposeBag)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI

extension VersionUpdateProtocol where Self: APPViewController {
    var localTimeZone: Foundation.TimeZone { .current }

    func popForceUpdateAlert(superSignStatus: SuperSignStatus, downloadLink: String) {
        if
            superSignStatus.isMaintenance,
            let endTime = superSignStatus.endTime
        {
            alertSuperSignMaintain(endTime)
        }
        else {
            if appSyncViewModel.getIsPoppedAutoUpdate() {
                popRemoveAppAndReinstall(urlString: downloadLink)
            }
            else {
                popConfirmUpdateAlert(urlString: downloadLink)
            }
        }
    }

    private func alertSuperSignMaintain(_ endTime: Date) {
        guard !Alert.shared.isShown() else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = localTimeZone
        dateFormatter.dateFormat = "MM/dd HH:mm"

        let endTimeStr = dateFormatter.string(from: endTime)

        Alert.shared.show(
            Localize.string("common_tip_title_warm"),
            Localize.string("common_super_signature_maintenance", endTimeStr),
            confirm: { exit(0) },
            cancel: nil)
    }

    private func popConfirmUpdateAlert(urlString: String) {
        guard !Alert.shared.isShown() else { return }

        Alert.shared.show(
            nil,
            Localize.string("update_new_version_content"),
            confirm: { [weak self] in
                if
                    let url = URL(string: urlString),
                    UIApplication.shared.canOpenURL(url)
                {
                    UIApplication.shared.open(url)
                    self?.appSyncViewModel.setIsPoppedAutoUpdate(true)
                }
            },
            confirmText: Localize.string("update_proceed_now"),
            cancel: { exit(0) },
            cancelText: Localize.string("update_exit"))
    }

    private func popRemoveAppAndReinstall(urlString: String) {
        guard !Alert.shared.isShown() else { return }

        let appName = Bundle.main.appName

        Alert.shared.show(
            Localize.string("update_already_install", [appName]),
            Localize.string("update_remove_app_and_reinstall", [appName]),
            confirm: {
                if
                    let url = URL(string: urlString),
                    UIApplication.shared.canOpenURL(url)
                {
                    UIApplication.shared.open(url) { _ in exit(0) }
                }
            },
            confirmText: Localize.string("update_proceed_now"),
            cancel: { exit(0) },
            cancelText: Localize.string("update_exit"))
    }
}
