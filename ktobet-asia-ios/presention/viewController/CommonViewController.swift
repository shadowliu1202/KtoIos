import RxSwift
import SharedBu
import UIKit

class CommonViewController: APPViewController, VersionUpdateProtocol {
  @Injected private var playerViewModel: PlayerViewModel
  @Injected private var localStorageRepo: LocalStorageRepository

  @Injected var appSyncViewModel: AppSynchronizeViewModel

  private var disposeBag = DisposeBag()
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

    playerViewModel
      .checkIsLogged()
      .observe(on: MainScheduler())
      .subscribe(onSuccess: { [weak self] isLogin in
        guard isLogin == false
        else {
          self?.executeLogout()
          return
        }

        self?.popForceUpdateAlert(
          superSignStatus: info.superSignStatus,
          downloadLink: info.link)

      }, onFailure: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: viewDisappearBag)
  }

  private func executeLogout() {
    playerViewModel
      .logout()
      .subscribe(on: MainScheduler.instance).subscribe(onCompleted: { [weak self] in
        self?.disposeBag = DisposeBag()
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
      }, onError: {
        Logger.shared.debug($0.localizedDescription)
      })
      .disposed(by: disposeBag)
  }
}
