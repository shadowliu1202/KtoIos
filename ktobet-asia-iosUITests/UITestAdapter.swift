import SwiftUI
import UIKit

class UITestAdapter {
    static func getViewController(_ viewName: String) -> UIViewController? {
        if viewName == "LoginView" {
            @Injected var viewModel: LoginViewModel
            return UIHostingController(rootView: LoginView(viewModel: viewModel, isForceChinese: false, onLogin: { _, _ in }, onOTPLogin: {}, toggleForceChinese: {}))
        } else if viewName == "PasteableTextField" {
            let vc = UIViewController()
            let tf = PasteableTextField()
            tf.disablePaste = true
            tf.backgroundColor = .blue
            tf.accessibilityIdentifier = "PasteableTextField"
            vc.view.addSubview(tf, constraints: .fillWidth())
            tf.constrain(to: vc.view, constraints: [.equal(\.centerYAnchor)])
            vc.view.backgroundColor = .primaryDefault
            return vc
        } else if viewName == "SwiftUIInputText" {
            var str = ""
            let text = Binding<String>(get: { str }, set: { str = $0 })

            let tf = SwiftUIInputText(
                placeHolder: "",
                textFieldText: text,
                textFieldType: GeneralType()
            )
            .accessibilityIdentifier("SwiftUIInputText")

            return UIHostingController(rootView: tf)
        }

        return nil
    }
}
