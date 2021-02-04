//
//  AppDelegate.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/22.
//

import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        application.statusBarStyle = .lightContent
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        return true
    }
    // MARK: UISceneSession Lifecycle
}
