//
//  UIWindowExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/18.
//

import Foundation
import UIKit


extension UIWindow {
    var topViewController: UIViewController? {
        // 用遞迴的方式找到最後被呈現的 view controller。
        if var topVC = rootViewController {
            while let vc = topVC.presentedViewController {
                topVC = vc
            }
            return topVC
        } else {
            return nil
        }
    }
}
