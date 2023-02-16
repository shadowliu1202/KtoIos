import RxSwift
import SharedBu
import UIKit

struct VersionUpdateInfo {
  let version: Version
  let superSignStatus: SuperSignStatus
  let isFromEnterForeground: Bool
  let action: Version.UpdateAction
  
  var link: String {
    version.apkLink
  }
  
  var shouldPerformUpdateAction: Bool {
    action == .compulsoryupdate ||
    (action == .optionalupdate && isFromEnterForeground)
  }
  
  init(
    version: Version,
    superSignStatus: SuperSignStatus,
    isFromEnterForeground: Bool
  ) {
    self.version = version
    self.superSignStatus = superSignStatus
    self.isFromEnterForeground = isFromEnterForeground
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
    syncAppVersion(isFromEnterForeground: false, disposeBag: disposeBag)
    registerAppEnterForeground(disposeBag)
  }

  private func syncAppVersion(isFromEnterForeground: Bool, disposeBag: DisposeBag) {
    Observable.combineLatest(
      appSyncViewModel.getLatestAppVersion().asObservable(),
      appSyncViewModel.getSuperSignStatus().asObservable()
    )
    .filter { _ in Configuration.isAutoUpdate }
    .map { version, superSignStatus in
      VersionUpdateInfo(
        version: version,
        superSignStatus: superSignStatus,
        isFromEnterForeground: isFromEnterForeground
      )
    }
    .subscribe(onNext: { [weak self] info in
      if info.action == .compulsoryupdate {
        self?.appSyncViewModel.setIsPoppedAutoUpdate(false)
      }
      
      self?.updateStrategy(from: info)
    })
    .disposed(by: disposeBag)
  }

  private func registerAppEnterForeground(_ disposeBag: DisposeBag) {
    NotificationCenter.default.rx
      .notification(UIApplication.willEnterForegroundNotification)
      .take(until: self.rx.deallocated)
      .subscribe(onNext: { [weak self] _ in
        self?.syncAppVersion(isFromEnterForeground: true, disposeBag: disposeBag)
      })
      .disposed(by: disposeBag)
  }
}

// MARK: - UI

extension VersionUpdateProtocol where Self: APPViewController {
  
  var localTimeZone: Foundation.TimeZone { .current }

  func popAlert(from info: VersionUpdateInfo, force: Bool = false) {
    guard info.shouldPerformUpdateAction || force else { return }
    
    switch info.action {
    case .compulsoryupdate:
      if
        info.superSignStatus.isMaintenance,
        let endTime = info.superSignStatus.endTime
      {
        alertSuperSignMaintain(endTime)
      }
      else {
        if appSyncViewModel.getIsPoppedAutoUpdate() {
          popRemoveAppAndReinstall(urlString: info.link)
        }
        else {
          popConfirmUpdateAlert(urlString: info.link)
        }
      }

    case .optionalupdate:
      guard !info.superSignStatus.isMaintenance else { return }
      popConfirmUpdateAlert(urlString: info.link)

    default:
      return
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
