//
//  AlertView.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/17.
//

import Foundation
import UIKit

class Alert {
    private static var alertOutsideBackground: UIView = {
        let view = UIView(frame: UIWindow.key!.frame)
        view.backgroundColor = .black80
        return view
    }()

    class func show(_ title: String?,
                    _ message: String?,
                    confirm: (() -> Void)?,
                    confirmText: String? = nil,
                    cancel: (() -> Void)?,
                    cancelText: String? = nil,
                    tintColor: UIColor? = nil) {
        if let topVc = UIApplication.topViewController() {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.view.backgroundColor = UIColor.white
                alert.view.layer.cornerRadius = 14
                alert.view.clipsToBounds = true

                let confirmAction = UIAlertAction(title: confirmText ?? Localize.string("common_confirm"), style: .default) { (action) in
                    removeBackgroundView()
                    confirm?()
                }

                let cancelction = UIAlertAction(title: cancelText ?? Localize.string("common_cancel"), style: .cancel) { (action) in
                    removeBackgroundView()
                    cancel?()
                }

                cancelction.setValue(tintColor ?? UIColor.redForLightFull, forKey: "titleTextColor")
                confirmAction.setValue(tintColor ?? UIColor.redForLightFull, forKey: "titleTextColor")
                alert.addAction(confirmAction)

                if cancel != nil {
                    alert.addAction(cancelction)
                }

                topVc.present(alert, animated: true, completion: nil)

                if !(UIWindow.key?.subviews.contains(alertOutsideBackground) ?? false) {
                    UIWindow.key?.addSubview(alertOutsideBackground)
                }
            }
        }
    }

    private static func removeBackgroundView() {
        if let topVC = UIApplication.topViewController(), !(topVC is UIAlertController) {
            alertOutsideBackground.removeFromSuperview()
        }
    }

    class func dismiss(completion: (() -> ())?) {
        guard let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController,
              topVc is UIAlertController else {
                  completion?()
                  return
              }

        topVc.dismiss(animated: true, completion: completion)
    }
    
    class func isShown() -> Bool {
        if let topVC = UIApplication.topViewController(), topVC is UIAlertController {
            return true
        }
        return false
    }
}
