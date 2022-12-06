
import UIKit
import IQKeyboardManagerSwift
import RxSwift
import SharedBu
import WebKit
import Firebase
import SwiftUI
import FirebaseCore

public var isTesting: Bool { ProcessInfo.processInfo.arguments.contains("isTesting") }

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    @Injected private var localStorageRepo: LocalStorageRepository
    
    private (set) var reachabilityObserver: NetworkStateMonitor?
    
    private weak var timer: Timer?
    
    private var networkControlWindow: NetworkControlWindow?
    private var logRecorderViewWindow = LogRecorderViewWindow(
        frame: CGRect(x: UIScreen.main.bounds.width - 50, y: 80, width: 50, height: 50)
    )
    
    /// For recive message at phone lock state
    var backgroundUpdateTask = UIBackgroundTaskIdentifier(rawValue: 0)
    
    let disposeBag = DisposeBag()
    
    var window: UIWindow?
    
    var isDebugModel = false
    
    var debugController: MainDebugViewController?
    
    var restrictRotation:UIInterfaceOrientationMask = .portrait
    
    override init() {
        super.init()

        NetworkStateMonitor.setup(
            connected: networkDidConnect,
            disconnected: networkDisConnect,
            requestError: requestErrorWhenRetry
        )
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        guard !isInTesting(),
              !isInSwiftUIPreviewLiveMode()
        else { return true }
        
        Logger.shared.info("APP launch.")
        
        CookieUtil.shared.loadCookiesFromUserDefault()
        
        FirebaseApp.configure()
        
        configUISetting(application)
        
        Theme.shared.changeEntireAPPFont(by: localStorageRepo.getSupportLocale())
        
        SharedBu.Platform.init().debugBuild()
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let storyboardId = UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController?.restorationIdentifier ?? ""
        
        if storyboardId != "LandingNavigation" {
            checkLoginStatus()
        } else {
            checkMaintenanceStatus()
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.restrictRotation
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        self.backgroundUpdateTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundUpdateTask()
        })
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.endBackgroundUpdateTask()
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        CookieUtil.shared.saveCookieToUserDefault()
        Logger.shared.info("APP terminate.")
    }
}

// MARK: - UI Setting

private extension AppDelegate {
    
    func configUISetting(_ application: UIApplication) {
        IQKeyboardManager.shared.enable = true
        UIView.appearance().isExclusiveTouch = true
        UICollectionView.appearance().isExclusiveTouch = true
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        } else {
            application.statusBarStyle = .lightContent
        }
        
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithTransparentBackground()
        barAppearance.titleTextAttributes = [.foregroundColor: UIColor.whitePure, .font: Theme.shared.getNavigationTitleFont(by: localStorageRepo.getSupportLocale())]
        barAppearance.backgroundColor = UIColor.black131313.withAlphaComponent(0.9)
        
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
        UINavigationBar.appearance().standardAppearance = barAppearance
        
        if Configuration.debugGesture {
            self.addDebugGesture()
        }
        if Configuration.manualControlNetwork {
            self.addNetworkControlGesture()
        }
        
        let launchController = LaunchViewController.initFrom(storyboard: "Launch")
        window?.rootViewController = launchController
        window?.makeKeyAndVisible()
    }
    
    func addDebugGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(debugGesture(_:)))
        gesture.numberOfTouchesRequired = 2
        gesture.numberOfTapsRequired = 2
        self.window?.addGestureRecognizer(gesture)
    }
    
    @objc func debugGesture(_ gesture: UITapGestureRecognizer) {
        guard !isDebugModel else { return }
        
        let storyboard = UIStoryboard(name: "Launch", bundle: nil)
        self.debugController = storyboard.instantiateViewController(withIdentifier: "MainDebugViewController") as? MainDebugViewController
        self.debugController?.cancelHandle = { [weak self] in
            self?.debugController?.view.removeFromSuperview()
            self?.debugController = nil
            self?.isDebugModel = false
        }
        
        self.window?.addSubview(self.debugController!.view)
        self.isDebugModel = true
        
        logRecorderViewWindow.isHidden = false
    }
    
    func addNetworkControlGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(addNetworkFloatButton(_:)))
        gesture.numberOfTouchesRequired = 2
        gesture.numberOfTapsRequired = 2
        self.window?.addGestureRecognizer(gesture)
    }
    
    @objc func addNetworkFloatButton(_ gesture: UITapGestureRecognizer) {
        if networkControlWindow == nil {
            var rightPadding: CGFloat = 80
            var bottomPadding: CGFloat = 80
            if let window = UIApplication.shared.windows.first {
                rightPadding += window.safeAreaInsets.right
                bottomPadding += window.safeAreaInsets.bottom
            }
            networkControlWindow = NetworkControlWindow(frame: CGRect(x: UIScreen.main.bounds.width - rightPadding, y: UIScreen.main.bounds.height - bottomPadding, width: 56, height: 56))
            networkControlWindow?.isHidden = false
            networkControlWindow?.touchUpInside = { isNetworkConnected in
                if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
                    if isNetworkConnected {
                        topVc.networkDidConnected()
                    } else {
                        topVc.networkDisConnected()
                    }
                }
            }
        }
    }
    
    func endBackgroundUpdateTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundUpdateTask)
        self.backgroundUpdateTask = UIBackgroundTaskIdentifier.invalid
    }
}

// MARK: - Status check

private extension AppDelegate {
    
    func checkLoginStatus() {
        let viewModel = Injectable.resolveWrapper(NavigationViewModel.self)
        
        viewModel.checkIsLogged()
            .subscribe(
                onSuccess: {[weak self] isLogged in
                    if isLogged {
                        CustomServicePresenter.shared.initService()
                    } else {
                        self?.logoutToLanding()
                    }},
                onFailure: {[weak self] error in
                    if error.isUnauthorized() {
                        self?.logoutToLanding()
                    } else {
                        UIApplication.topViewController()?.handleErrors(error)
                    }}
            )
            .disposed(by: disposeBag)
    }
    
    func checkMaintenanceStatus() {
        let viewModel = Injectable.resolveWrapper(ServiceStatusViewModel.self)
        
        viewModel.output.portalMaintenanceStatus
            .subscribe(onNext: { status in
                switch status {
                case is MaintenanceStatus.AllPortal:
                    NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    func logoutToLanding() {
        let playerViewModel = Injectable.resolveWrapper(PlayerViewModel.self)
        
        playerViewModel
            .logout()
            .subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Network

extension AppDelegate {
    
    private func networkDidConnect() {
        if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
            topVc.networkDidConnected()
        }
    }
    
    private func networkDisConnect() {
        if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
            topVc.networkDisConnected()
        }
    }
    
    func forceCheckNetworkStatus() {
        self.timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.debounceCheckNetworkStatus), userInfo: nil, repeats: false)
        self.timer = nextTimer
    }
    
    @objc private func debounceCheckNetworkStatus() {
        self.reachabilityObserver?.setForceCheck()
    }
    
    private func requestErrorWhenRetry(error: Error) {
        print("\(error)")
    }
}


// MARK: - Test Task

private extension AppDelegate {
    
    func isInTesting() -> Bool {
        guard isTesting else { return false }
        
        configTesting()
        
        return true
    }
    
    func configTesting() {
        let environment = ProcessInfo.processInfo.environment
        let target: UIViewController
        
        if let viewName = environment["viewName"],
           let rootViewController = UITestAdapter.getViewController(viewName) {
            target = rootViewController
        }
        else {
            target = .init()
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = target
        window?.makeKeyAndVisible()
    }
    
    func isInSwiftUIPreviewLiveMode() -> Bool {
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
