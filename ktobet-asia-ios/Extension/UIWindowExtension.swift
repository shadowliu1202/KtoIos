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
    }
    else {
      return nil
    }
  }

  static var key: UIWindow? {
    if #available(iOS 13, *) {
      return UIApplication.shared.windows.first { $0.isKeyWindow }
    }
    else {
      return UIApplication.shared.keyWindow
    }
  }
}

extension UIDevice {
  var hasNotch: Bool {
    if #available(iOS 11.0, tvOS 11.0, *) {
      return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
    }

    return false
  }
}
