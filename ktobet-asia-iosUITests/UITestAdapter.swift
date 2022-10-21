import UIKit
import SwiftUI

class UITestAdapter {
    static func getViewController(_ viewName: String) -> UIViewController? {
        if viewName == "LoginView" {
            return UIHostingController(rootView: LoginView(onLogin: { _, _ in }, onResetPassword: {}))
        } else if viewName == "PasteableTextField" {
            let vc = UIViewController()
            let tf = PasteableTextField()
            tf.disablePaste = true
            tf.backgroundColor = .blue
            tf.accessibilityIdentifier = "PasteableTextField"
            vc.view.addSubview(tf, constraints: .fillWidth())
            tf.constrain(to: vc.view, constraints: [.equal(\.centerYAnchor)])
            vc.view.backgroundColor = .red
            return vc
        }
        
        return nil
    }
}
