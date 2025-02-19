import Firebase
import FirebaseCore
import IQKeyboardManagerSwift
import RxSwift
import SDWebImage
import sharedbu
import SwiftUI
import UIKit
import WebKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
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

    Task { await Injection.shared.setupNetworkInfra() }
    
    #if !DEV
      crashHandler()
    #endif

    AppLocaleInitializer().initLocale()

    sharedbu.Platform().debugBuild()

    updateAndLogInstallDate(applicationStorage, keychain)

    configUISetting(application)
    
    setupImageDownloader()
    
    return true
  }
  
  private func setupImageDownloader() {
    let downloaderConfig = SDWebImageDownloaderConfig()
    downloaderConfig.sessionConfiguration = URLSessionConfiguration.default
    downloaderConfig.downloadTimeout = .infinity
      
    let downloader = SDWebImageDownloader(config: downloaderConfig)
    downloader.setValue("application/json", forHTTPHeaderField: "Accept")
    downloader.setValue("AppleWebKit/" + Configuration.getKtoAgent(), forHTTPHeaderField: "User-Agent")
    
    SDWebImageManager.defaultImageLoader = downloader
  }
  
  private func crashHandler() {
    FirebaseApp.configure()
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
  
    NSSetUncaughtExceptionHandler { exception in
      let currentVC = UIApplication.topViewController()
      Crashlytics.crashlytics().setCustomValue(currentVC, forKey: "current vc")
      
      guard let error = exception as? Error else {
        Crashlytics.crashlytics().setCustomValue(exception, forKey: "exception")
        return
      }
      Crashlytics.crashlytics().record(error: error)
    }
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
    lazy var cookieManager = Injectable.resolveWrapper(CookieManager.self)
    
    WKWebsiteDataStore.default().removeData(
      ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
      modifiedSince: Date(timeIntervalSince1970: 0),
      completionHandler: { })
    
    if Injection.shared.networkReadyRelay.value {
      cookieManager.saveCookiesToUserDefault()
    }
    
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
    let supportLocale = Injectable.resolveWrapper(PlayerConfiguration.self).supportLocale
    barAppearance.configureWithTransparentBackground()
    barAppearance.titleTextAttributes = [
      .foregroundColor: UIColor.greyScaleWhite,
      .font: Theme.shared.getNavigationTitleFont(by: supportLocale)
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
    @Injected var maintenanceViewModel: MaintenanceViewModel
    @Injected var customerServiceViewModel: CustomerServiceViewModel
    
    Task { [maintenanceViewModel, customerServiceViewModel] in
      async let maintenanceStatus = maintenanceViewModel.pullMaintenanceStatus()
      async let isPlayerInChat = customerServiceViewModel.isPlayerInChat.first().value
      
      guard
        await maintenanceStatus is MaintenanceStatus.AllPortal,
        let isPlayerInChat = try? await isPlayerInChat
      else { return }
      
      if isPlayerInChat {
        try? await CustomServicePresenter.shared.closeService().value
        
        Alert.shared.show(
          Localize.string("common_maintenance_notify"),
          Localize.string("common_maintenance_chat_close"),
          confirm: {
            NavigationManagement.sharedInstance.goTo(
              storyboard: "Maintenance",
              viewControllerId: "PortalMaintenanceViewController")
          },
          cancel: nil)
      }
      else {
        NavigationManagement.sharedInstance.goTo(
          storyboard: "Maintenance",
          viewControllerId: "PortalMaintenanceViewController")
      }
    }
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
}

// MARK: - Install Date check

extension AppDelegate {
  private func updateAndLogInstallDate(_ applicationStorage: ApplicationStorable, _ keychain: KeychainStorable) {
    guard applicationStorage.getAppIsFirstLaunch() else { return }

    applicationStorage.setAppWasLaunch()

    let now = Date().convertdateToUTC()

    if keychain.getInstallDate() == nil {
      keychain.setInstallDate(now)
      AnalyticsManager.brandNewInstall()
    }
    else {
      let lastInstallDay = keychain.getInstallDate()!
      keychain.setInstallDate(now)
      let surviveDay = lastInstallDay.betweenTwoDay(sencondDate: now)
      AnalyticsManager.appReinstall(
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
    
    Injection.shared.networkReadyRelay.accept(true)
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
