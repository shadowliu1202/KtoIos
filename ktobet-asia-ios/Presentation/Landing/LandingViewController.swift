import RxSwift
import sharedbu
import UIKit

class LandingViewController: APPViewController, VersionUpdateProtocol {
  @Injected private var localStorageRepo: LocalStorageRepository

  @Injected var appSyncViewModel: AppSynchronizeViewModel

  private var viewDisappearBag = DisposeBag()

  lazy var localTimeZone = localStorageRepo.localeTimeZone()

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    syncAppVersionUpdate(viewDisappearBag)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewDisappearBag = DisposeBag()
  }

  // MARK: VersionUpdateProtocol
  func updateStrategy(from info: VersionUpdateInfo) {
    guard info.action == .compulsoryupdate else { return }

    popForceUpdateAlert(
      superSignStatus: info.superSignStatus,
      downloadLink: info.link)
  }
}
