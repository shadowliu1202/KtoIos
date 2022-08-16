import UIKit
import SwiftUI

class UITestAdapter {
    static func getViewController(_ viewName: String) -> UIViewController? {
        if viewName == "LoginView" {
            return UIHostingController(rootView: LoginView(onLogin: { _, _ in }, onResetPassword: {}))
        }
        
        return nil
    }
}
