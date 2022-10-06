
import UIKit
import IQKeyboardManagerSwift
import RxSwift
import SharedBu
import WebKit
import Firebase
import SwiftUI
import FirebaseCore

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    private(set) var reachabilityObserver: NetworkStateMonitor?
    private weak var timer: Timer?
    
    var window: UIWindow?
    var isDebugModel = false
    var debugController: MainDebugViewController?
    let disposeBag = DisposeBag()
    private var networkControlWindow: NetworkControlWindow?
    private let playerLocaleConfiguration = DI.resolve(PlayerLocaleConfiguration.self)!
    
    override init() {
        super.init()
        NetworkStateMonitor.setup(connected: networkDidConnect, disconnected: networkDisConnect, requestError: requestErrorWhenRetry)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("isUITesting") {
            let viewName = ProcessInfo.processInfo.environment["viewName"] ?? ""
            guard let rootViewController = UITestAdapter.getViewController(viewName) else { fatalError("Not in UITesting") }
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = rootViewController
            self.window?.makeKeyAndVisible()
            return true
        }
        
        CookieUtil.shared.loadCookiesFromUserDefault()
        FirebaseApp.configure()
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
        barAppearance.titleTextAttributes = [.foregroundColor: UIColor.whiteFull, .font: Theme.shared.getNavigationTitleFont(by: playerLocaleConfiguration.getSupportLocale())]
        barAppearance.backgroundColor = UIColor.black_two90
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().scrollEdgeAppearance = barAppearance
        UINavigationBar.appearance().standardAppearance = barAppearance
        Theme.shared.changeEntireAPPFont(by: playerLocaleConfiguration.getSupportLocale())
        
        if Configuration.debugGesture {
            self.addDebugGesture()
        }
        if Configuration.manualControlNetwork {
            self.addNetworkControlGesture()
        }
        
        SharedBu.Platform.init().debugBuild()
        
        return true
    }
    
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
    
    private func requestErrorWhenRetry(error: Error) {
        print("\(error)")
    }
    
    func forceCheckNetworkStatus() {
        self.timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.debounceCheckNetworkStatus), userInfo: nil, repeats: false)
        self.timer = nextTimer
    }
    
    @objc private func debounceCheckNetworkStatus() {
        self.reachabilityObserver?.setForceCheck()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let storyboardId =  UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController?.restorationIdentifier ?? ""
        if storyboardId != "LandingNavigation" {
            let viewModel = DI.resolve(NavigationViewModel.self)!
            viewModel
                .checkIsLogged()
                .subscribe { (isLogged) in
                    CustomServicePresenter.shared.initCustomerService()

                    if !isLogged {
                        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
                    }
                } onError: { (error) in
                    if error.isUnauthorized() {
                        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
                    } else {
                        UIApplication.topViewController()?.handleErrors(error)
                    }
                }.disposed(by: disposeBag)
        } else {
            let viewModel = DI.resolve(ServiceStatusViewModel.self)!
            viewModel.output.portalMaintenanceStatus.subscribe(onNext: { status in
                switch status {
                case is MaintenanceStatus.AllPortal:
                    UIApplication.topViewController()?.showUnLoginMaintenanAlert()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        }
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
    
    var restrictRotation:UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return self.restrictRotation
    }
    
    //----For recive message at phone lock state----//
    var backgroundUpdateTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
    func endBackgroundUpdateTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundUpdateTask)
        self.backgroundUpdateTask = UIBackgroundTaskIdentifier.invalid
    }
    func applicationWillResignActive(_ application: UIApplication) {
        self.backgroundUpdateTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.endBackgroundUpdateTask()
        })
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.endBackgroundUpdateTask()

    }
    //----For recive message at phone lock state----//
    
    func applicationWillTerminate(_ application: UIApplication) {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        CookieUtil.shared.saveCookieToUserDefault()
    }
}
