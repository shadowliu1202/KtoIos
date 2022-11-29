import Foundation
import UIKit

protocol AlertProtocol {
    func show(_ title: String?,
              _ message: String?,
              confirm: (() -> Void)?,
              confirmText: String?,
              cancel: (() -> Void)?,
              cancelText: String?,
              tintColor: UIColor?)
    func dismiss(completion: (() -> ())?)
    func isShown() -> Bool
}

extension AlertProtocol {
    func show(_ title: String?,
                   _ message: String?,
                   confirm: (() -> Void)?,
                   confirmText: String? = nil,
                   cancel: (() -> Void)?,
                   cancelText: String? = nil,
              tintColor: UIColor? = nil) {
        self.show(title, message, confirm: confirm, confirmText: confirmText, cancel: cancel, cancelText: cancelText, tintColor: tintColor)
    }
}

class Alert: AlertProtocol {
    static var shared: AlertProtocol = Alert()
    
    private var alertOutsideBackground: UIView = {
        let view = UIView(frame: UIWindow.key!.frame)
        view.backgroundColor = .black131313.withAlphaComponent(0.8)
        return view
    }()

    private init() {}

    func show(_ title: String?,
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
                    self.removeBackgroundView()
                    confirm?()
                }

                let cancelction = UIAlertAction(title: cancelText ?? Localize.string("common_cancel"), style: .cancel) { (action) in
                    self.removeBackgroundView()
                    cancel?()
                }

                cancelction.setValue(tintColor ?? UIColor.redD90101, forKey: "titleTextColor")
                confirmAction.setValue(tintColor ?? UIColor.redD90101, forKey: "titleTextColor")
                alert.addAction(confirmAction)

                if cancel != nil {
                    alert.addAction(cancelction)
                }

                topVc.present(alert, animated: true, completion: nil)

                if !(UIWindow.key?.subviews.contains(self.alertOutsideBackground) ?? false) {
                    UIWindow.key?.addSubview(self.alertOutsideBackground)
                }
            }
        }
    }

    private func removeBackgroundView() {
        if let topVC = UIApplication.topViewController(), !(topVC is UIAlertController) {
            alertOutsideBackground.removeFromSuperview()
        }
    }

    func dismiss(completion: (() -> ())?) {
        guard let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController,
              topVc is UIAlertController else {
                  completion?()
                  return
              }
        alertOutsideBackground.removeFromSuperview()
        topVc.dismiss(animated: true, completion: completion)
    }
    
    func isShown() -> Bool {
        if let topVC = UIApplication.topViewController(), topVC is UIAlertController {
            return true
        }
        return false
    }
}
