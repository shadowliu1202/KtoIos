
import SwiftUI

struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var showPassword: Bool

    var isPasswordType: Bool = false
    var configuration = { (uiTextField: UITextField) in }
    var editingDidEnd = {}

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        configuration(view)
        view.addAction(UIAction(handler: { _ in
            self.$text.wrappedValue = view.text ?? ""
        }), for: .editingChanged)
        
        view.addAction(UIAction(handler: { _ in
            self.$isFirstResponder.wrappedValue = false
            self.editingDidEnd()
        }), for: .editingDidEnd)
        
        view.addAction(UIAction(handler: { _ in
            self.$isFirstResponder.wrappedValue = false
            self.editingDidEnd()
        }), for: .editingDidEndOnExit)
        
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isSecureTextEntry = isPasswordType && !showPassword
        switch isFirstResponder {
        case true:
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        case false:
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }
}
