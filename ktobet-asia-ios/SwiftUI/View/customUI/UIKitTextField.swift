
import SwiftUI

struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var showPassword: Bool

    var isPasswordType: Bool
    var configuration = { (uiTextField: UITextField) in }
    var editingDidEnd = { (text: String) in }
    
    let disablePaste: Bool
    let keyboardType: UIKeyboardType

    init(text: Binding<String>, isFirstResponder: Binding<Bool>, showPassword: Binding<Bool>, isPasswordType: Bool, disablePaste: Bool = false, keyboardType: UIKeyboardType = .default, configuration: @escaping (UITextField) -> () = { (uiTextField: UITextField) in }, editingDidEnd: @escaping (String) -> () = {(text: String) in }) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self._showPassword = showPassword
        self.isPasswordType = isPasswordType
        self.disablePaste = disablePaste
        self.keyboardType = keyboardType
        self.configuration = configuration
        self.editingDidEnd = editingDidEnd
    }

    func makeUIView(context: Context) -> UITextField {
        let view = PasteableTextField()
        view.text = text
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.keyboardType = keyboardType
        view.disablePaste = disablePaste
        configuration(view)
        
        view.delegate = context.coordinator
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textChanged), for: .editingChanged)
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditEnd), for: .editingDidEnd)
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditEnd), for: .editingDidEndOnExit)
        
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
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
        Coordinator($isFirstResponder, $text, keyboardType, editingDidEnd)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        @Binding private var isFirstResponder: Bool
        
        let keyboardType: UIKeyboardType
        var editingDidEnd = { (text: String) in }
        
        init(_ isFirstResponder: Binding<Bool>, _ text: Binding<String>, _ keyboardType: UIKeyboardType, _ editingDidEnd: @escaping (String) -> () ) {
            self._isFirstResponder = isFirstResponder
            self._text = text
            self.keyboardType = keyboardType
            self.editingDidEnd = editingDidEnd
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
        
        @objc func textChanged(_ sender: UITextField) {
            guard let inputText = sender.text?.halfWidth else { return }
            
            if keyboardType == .numberPad, !inputText.isEmpty,
               let amount = Double(inputText.replacingOccurrences(of: ",", with: ""))?.currencyFormatWithoutSymbol() {
                self.text = amount
                sender.text = amount
            } else {
                self.text = inputText
                sender.text = inputText
            }
        }
        
        @objc func textEditEnd(_ sender: UITextField) {
            isFirstResponder = false
            
            if let senderText = sender.text, senderText != text {
                sender.text = text
            }
            
            sender.text = sender.text?.halfWidth
            editingDidEnd(sender.text ?? "")
        }
    }
}
