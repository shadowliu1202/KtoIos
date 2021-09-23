//
//  AppDelegate.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/22.
//

import UIKit
import IQKeyboardManagerSwift
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var isDebugModel = false
    var debugController: MainDebugViewController?
    let disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        application.statusBarStyle = .lightContent
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
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
        
        #if QAT
        self.addDebugGesture()
        #endif
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        let storyboardId =  UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.rootViewController?.restorationIdentifier ?? ""
        if storyboardId != "LoginNavigation" {
        let viewModel = DI.resolve(LaunchViewModel.self)!
        viewModel
            .checkIsLogged()
            .subscribe { (isLogged) in
                if !isLogged {
                    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                }
            } onError: { (error) in
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
            }.disposed(by: disposeBag)
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
    
    var restrictRotation:UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return self.restrictRotation
    }
}
