//
//  AppDelegate.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/22.
//

import UIKit
import IQKeyboardManagerSwift
import RxSwift
import Connectivity
import SharedBu
import WebKit
import Firebase

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    private let localStorageRepository = DI.resolve(LocalStorageRepository.self)!
    private(set) var reachabilityObserver: ReachabilityHandler?
    private weak var timer: Timer?
    
    var window: UIWindow?
    var isDebugModel = false
    var debugController: MainDebugViewController?
    let disposeBag = DisposeBag()
    private var networkControlWindow: NetworkControlWindow?
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if Configuration.enableCrashlytics {
            FirebaseApp.configure()
        }

        IQKeyboardManager.shared.enable = true
        UIView.appearance().isExclusiveTouch = true
        UICollectionView.appearance().isExclusiveTouch = true
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        } else {
            application.statusBarStyle = .lightContent
        }
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            let navigationBar = UINavigationBar()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.whiteFull]
            appearance.backgroundColor = UIColor.black_two
            navigationBar.isTranslucent = true
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().standardAppearance = appearance
        }
        
        if Configuration.debugGesture {
            self.addDebugGesture()
        }
        if Configuration.manualControlNetwork {
            self.addNetworkControlGesture()
        }

        //MARK: 待VN上線時移除
        let gesture = UITapGestureRecognizer(target: self, action: #selector(alloweVNGesture(_:)))
        gesture.numberOfTouchesRequired = 3
        gesture.numberOfTapsRequired = 3
        self.window?.addGestureRecognizer(gesture)

        reachabilityObserver = ReachabilityHandler.shared(connected: didConnect, disconnected: disConnect, requestError: requestErrorWhenRetry)
        
        SharedBu.Platform.init().debugBuild()
        
        if UserDefaults.standard.string(forKey: "cultureCode") == nil {
            initialCultureCode()
        }
        
        return true
    }

    @objc func alloweVNGesture(_ gesture: UITapGestureRecognizer) {
        Configuration.isAllowedVN.toggle()
    }
    
    private func didConnect(c: Connectivity) {
        if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
            topVc.networkDidConnected()
        }
    }
    
    private func disConnect(c: Connectivity) {
        if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
            topVc.networkDisConnected()
        }
    }
    
    private func requestErrorWhenRetry(error: Error) {
        print("\(error)")
    }
    
    private func initialCultureCode() {
        let localeCultureCode = systemLocaleToCultureCode()
        localStorageRepository.setCultureCode(localeCultureCode)
    }
    
    private func systemLocaleToCultureCode() -> String {
        switch Locale.current.languageCode {
        case "vi":
            return SupportLocale.Vietnam.shared.cultureCode()
        case "zh":
            fallthrough
        default:
            return SupportLocale.China.shared.cultureCode()
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
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let storyboardId =  UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController?.restorationIdentifier ?? ""
        if storyboardId != "LoginNavigation" {
            let viewModel = DI.resolve(LaunchViewModel.self)!
            viewModel
                .checkIsLogged()
                .subscribe { (isLogged) in
                    CustomServicePresenter.shared.observeCustomerService().observeOn(MainScheduler.asyncInstance).subscribe(onCompleted: {
                        print("Completed")
                    }).disposed(by: self.disposeBag)

                    if !isLogged {
                        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                    }
                } onError: { (error) in
                    if error.isUnauthorized() {
                        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                    } else {
                        UIApplication.topViewController()?.handleErrors(error)
                    }
                }.disposed(by: disposeBag)
        } else {
            let viewModel = DI.resolve(ServiceStatusViewModel.self)!
            viewModel.output.portalMaintenanceStatus.drive(onNext: { status in
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
            networkControlWindow?.touchUpInside = { isConnected in
                if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
                    if isConnected {
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
    }
}
