
import SwiftUI

struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var showPassword: Bool

    var isPasswordType: Bool
    var configuration = { (uiTextField: UITextField) in }
    var editingDidEnd = {}
    
    let keyboardType: UIKeyboardType

    init(text: Binding<String>, isFirstResponder: Binding<Bool>, showPassword: Binding<Bool>, isPasswordType: Bool, keyboardType: UIKeyboardType = .default, configuration: @escaping (UITextField) -> () = { (uiTextField: UITextField) in }, editingDidEnd: @escaping () -> () = {}) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self._showPassword = showPassword
        self.isPasswordType = isPasswordType
        self.keyboardType = keyboardType
        self.configuration = configuration
        self.editingDidEnd = editingDidEnd
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.keyboardType = keyboardType
        configuration(view)
        view.addAction(UIAction(handler: { _ in
            guard let inputText = view.text else { return }
            
            if inputText.isEmpty {
                text = inputText
                return
            }
            
            if keyboardType == .numberPad {
                guard let amount = Double(inputText.replacingOccurrences(of: ",", with: ""))?.currencyFormatWithoutSymbol() else { return }
                text = amount
                return
            }
            
            text = inputText
        }), for: .editingChanged)
        
        view.addAction(UIAction(handler: { _ in
            self.isFirstResponder = false
            self.editingDidEnd()
        }), for: .editingDidEnd)
        
        view.addAction(UIAction(handler: { _ in
            self.isFirstResponder = false
            self.editingDidEnd()
        }), for: .editingDidEndOnExit)
        
        view.delegate = context.coordinator
        
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator($text, keyboardType)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        
        let keyboardType: UIKeyboardType

        init(_ text: Binding<String>, _ keyboardType: UIKeyboardType) {
            self.text = text
            self.keyboardType = keyboardType
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if keyboardType == .numberPad {
                let candidate = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: "")
                if candidate == "" { return true }
                let isWellFormatted = candidate.range(of: RegularFormat.currencyFormat.rawValue, options: .regularExpression) != nil
                return isWellFormatted
            }
            
            return true
        }
    }
}
