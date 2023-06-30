
import Firebase
import FirebaseCore
import IQKeyboardManagerSwift
import RxSwift
import SharedBu
import SwiftUI
import UIKit
import WebKit
import SDWebImage

@main
class AppDelegate: UIResponder, UIApplicationDelegate, CookieUtil {
  @Injected private var localStorageRepo: LocalStorageRepository
  @Injected private var applicationStorage: ApplicationStorable
  @Injected private var keychain: KeychainStorable

  private(set) var reachabilityObserver: NetworkStateMonitor?

  private weak var timer: Timer?

  private var networkControlWindow: NetworkControlWindow?
  private var logRecorderViewWindow = LogRecorderViewWindow(
    frame: CGRect(x: UIScreen.main.bounds.width - 50, y: 80, width: 50, height: 50))

  /// For recive message at phone lock state
  var backgroundUpdateTask = UIBackgroundTaskIdentifier(rawValue: 0)

  let disposeBag = DisposeBag()

  var window: UIWindow?

  var isDebugModel = false

  var debugController: MainDebugViewController?

  var restrictRotation: UIInterfaceOrientationMask = .portrait

  override init() {
    super.init()

    NetworkStateMonitor.shared.startNotifier()
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?)
    -> Bool
  {
    guard !Configuration.isTesting else {
      configTesting()
      return true
    }
    guard !isInSwiftUIPreviewLiveMode() else {
      return true
    }

    Logger.shared.info("APP launch.")

    loadCookiesFromUserDefault()

    checkingPortalHost()

    #if !DEV
      FirebaseApp.configure()
    #endif

    Theme.shared.changeEntireAPPFont(by: localStorageRepo.getSupportLocale())

    SharedBu.Platform().debugBuild()

    updateAndLogInstallDate(applicationStorage, keychain)

    configUISetting(application)

    SDWebImageDownloader.shared.config.downloadTimeout = .infinity
    
    return true
  }

  func applicationWillEnterForeground(_: UIApplication) {
    let storyboardId = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.rootViewController?
      .restorationIdentifier ?? ""

    if storyboardId != "LandingNavigation" {
      checkLoginStatus()
    }
    else {
      checkMaintenanceStatus()
    }
  }

  func application(_: UIApplication, supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask {
    self.restrictRotation
  }

  func applicationWillResignActive(_: UIApplication) {
    self.backgroundUpdateTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
      self.endBackgroundUpdateTask()
    })
  }

  func applicationDidBecomeActive(_: UIApplication) {
    self.endBackgroundUpdateTask()
  }

  func applicationWillTerminate(_: UIApplication) {
    WKWebsiteDataStore.default().removeData(
      ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
      modifiedSince: Date(timeIntervalSince1970: 0),
      completionHandler: { })
    saveCookieToUserDefault()
    Logger.shared.info("APP terminate.")
  }
}

// MARK: - UI Setting

extension AppDelegate {
  private func configUISetting(_ application: UIApplication) {
    IQKeyboardManager.shared.enable = true
    UIView.appearance().isExclusiveTouch = true
    UICollectionView.appearance().isExclusiveTouch = true

    if #available(iOS 13.0, *) {
      window?.overrideUserInterfaceStyle = .light
    }
    else {
      application.statusBarStyle = .lightContent
    }

    let barAppearance = UINavigationBarAppearance()
    barAppearance.configureWithTransparentBackground()
    barAppearance.titleTextAttributes = [
      .foregroundColor: UIColor.greyScaleWhite,
      .font: Theme.shared.getNavigationTitleFont(by: localStorageRepo.getSupportLocale())
    ]
    barAppearance.backgroundColor = UIColor.greyScaleDefault.withAlphaComponent(0.9)

    UINavigationBar.appearance().isTranslucent = true
    UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
    UINavigationBar.appearance().standardAppearance = barAppearance

    if Configuration.debugGesture {
      self.addDebugGesture()
    }
    if Configuration.manualControlNetwork {
      self.addNetworkControlGesture()
    }

    window = .init(frame: UIScreen.main.bounds)
    let launchController = LaunchViewController.initFrom(storyboard: "Launch")
    window?.rootViewController = launchController
    window?.makeKeyAndVisible()
  }

  private func addDebugGesture() {
    let gesture = UITapGestureRecognizer(target: self, action: #selector(debugGesture(_:)))
    gesture.numberOfTouchesRequired = 2
    gesture.numberOfTapsRequired = 2
    self.window?.addGestureRecognizer(gesture)
  }

  @objc
  private func debugGesture(_: UITapGestureRecognizer) {
    guard !isDebugModel else { return }

    let storyboard = UIStoryboard(name: "Launch", bundle: nil)
    self.debugController = storyboard
      .instantiateViewController(withIdentifier: "MainDebugViewController") as? MainDebugViewController
    self.debugController?.cancelHandle = { [weak self] in
      self?.debugController?.view.removeFromSuperview()
      self?.debugController = nil
      self?.isDebugModel = false
    }

    self.window?.addSubview(self.debugController!.view)
    self.isDebugModel = true

    logRecorderViewWindow.isHidden = false
  }

  private func addNetworkControlGesture() {
    let gesture = UITapGestureRecognizer(target: self, action: #selector(addNetworkFloatButton(_:)))
    gesture.numberOfTouchesRequired = 2
    gesture.numberOfTapsRequired = 2
    self.window?.addGestureRecognizer(gesture)
  }

  @objc
  private func addNetworkFloatButton(_: UITapGestureRecognizer) {
    if networkControlWindow == nil {
      var rightPadding: CGFloat = 80
      var bottomPadding: CGFloat = 80
      if let window = UIApplication.shared.windows.first {
        rightPadding += window.safeAreaInsets.right
        bottomPadding += window.safeAreaInsets.bottom
      }
      networkControlWindow = NetworkControlWindow(frame: CGRect(
        x: UIScreen.main.bounds.width - rightPadding,
        y: UIScreen.main.bounds.height - bottomPadding,
        width: 56,
        height: 56))
      networkControlWindow?.isHidden = false
    }
  }

  private func endBackgroundUpdateTask() {
    UIApplication.shared.endBackgroundTask(self.backgroundUpdateTask)
    self.backgroundUpdateTask = UIBackgroundTaskIdentifier.invalid
  }
}

// MARK: - Status check

extension AppDelegate {
  private func checkLoginStatus() {
    let viewModel = Injectable.resolveWrapper(NavigationViewModel.self)

    viewModel.checkIsLogged()
      .subscribe(onSuccess: { [weak self] isLogged in
        if isLogged {
          CustomServicePresenter.shared.initService()
        }
        else {
          self?.logoutToLanding()
        }
      }, onFailure: { [weak self] error in
        if error.isUnauthorized() {
          self?.logoutToLanding()
        }
        else {
          UIApplication.topViewController()?.handleErrors(error)
        }
      })
      .disposed(by: disposeBag)
  }

  private func checkMaintenanceStatus() {
    let viewModel = Injectable.resolveWrapper(ServiceStatusViewModel.self)

    viewModel.output.portalMaintenanceStatus
      .subscribe(onNext: { status in
        switch status {
        case is MaintenanceStatus.AllPortal:
          NavigationManagement.sharedInstance.goTo(
            storyboard: "Maintenance",
            viewControllerId: "PortalMaintenanceViewController")
        default:
          break
        }
      })
      .disposed(by: disposeBag)
  }

  private func logoutToLanding() {
    let playerViewModel = Injectable.resolveWrapper(PlayerViewModel.self)

    playerViewModel
      .logout()
      .subscribe(onCompleted: {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
      })
      .disposed(by: disposeBag)
  }

  private func checkingPortalHost() {
    @Injected var ktoURL: KtoURL
    ktoURL.observeCookiesChanged()
  }
}

// MARK: - Install Date check

extension AppDelegate {
  private func updateAndLogInstallDate(_ applicationStorage: ApplicationStorable, _ keychain: KeychainStorable) {
    guard applicationStorage.getAppIsFirstLaunch() else { return }

    applicationStorage.setAppWasLaunch()

    let now = Date().convertdateToUTC()

    if keychain.getInstallDate() == nil {
      keychain.setInstallDate(now)
      AnalyticsLog.shared.brandNewInstall()
    }
    else {
      let lastInstallDay = keychain.getInstallDate()!
      keychain.setInstallDate(now)
      let surviveDay = lastInstallDay.betweenTwoDay(sencondDate: now)
      AnalyticsLog.shared.appReinstall(
        lastInstallDate: lastInstallDay.convertdateToUTC().toDateString(),
        surviveDay: surviveDay)
    }
  }
}

// MARK: - Test Task

extension AppDelegate {
  private func configTesting() {
    let environment = ProcessInfo.processInfo.environment
    let target: UIViewController

    if
      let viewName = environment["viewName"],
      let rootViewController = UITestAdapter.getViewController(viewName)
    {
      target = rootViewController
    }
    else {
      target = .init()
    }

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = target
    window?.makeKeyAndVisible()
  }

  private func isInSwiftUIPreviewLiveMode() -> Bool {
    let previewing = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"

    if previewing {
      self.window = UIWindow(frame: UIScreen.main.bounds)
      self.window?.rootViewController = UIViewController()
      self.window?.makeKeyAndVisible()

      return true
    }
    else {
      return false
    }
  }
}
