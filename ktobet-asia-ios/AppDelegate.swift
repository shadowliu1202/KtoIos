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

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    private(set) var rechabilityObserver: ReachabilityHandler?
    private weak var timer: Timer?
    
    var window: UIWindow?
    var isDebugModel = false
    var debugController: MainDebugViewController?
    let disposeBag = DisposeBag()
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
        
        fetchLatestVersion()
        
        if Configuration.debugGesture {
            self.addDebugGesture()
        }
        
        rechabilityObserver = ReachabilityHandler.shared(connected: didConnect, disconnected: disConnect, requestError: requestErrorWhenRetry)
        
        SharedBu.Platform.init().debugBuild()
        return true
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
        if let topVc = UIApplication.topViewController() as? NetworkStatusDisplay {
            topVc.networkRequestHandle(error: error)
        }
    }
    
    func forceCheckNetworkStatus() {
        self.timer?.invalidate()
        let nextTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.debounceCheckNetworkStatus), userInfo: nil, repeats: false)
        self.timer = nextTimer
    }
    
    @objc private func debounceCheckNetworkStatus() {
        self.rechabilityObserver?.setForceCheck()
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
        }
        
        fetchLatestVersion()
    }
    
    private func fetchLatestVersion() {
        AppSynchronizeViewModel.shared.syncAppVersion()
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
}
