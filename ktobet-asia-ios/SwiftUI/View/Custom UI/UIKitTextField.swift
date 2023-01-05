
import SwiftUI

struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var showPassword: Bool

    var isPasswordType: Bool
    var configuration = { (uiTextField: UITextField) in }
    
    let disablePaste: Bool
    let keyboardType: UIKeyboardType
    let currencyFormatMaxDigits: Int?
    let maxLength: Int?
    
    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        showPassword: Binding<Bool>,
        isPasswordType: Bool,
        disablePaste: Bool = false,
        keyboardType: UIKeyboardType = .default,
        currencyFormatMaxDigits: Int?,
        maxLength: Int?,
        configuration: @escaping (UITextField) -> () = { (uiTextField: UITextField) in }
    ) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self._showPassword = showPassword
        self.isPasswordType = isPasswordType
        self.disablePaste = disablePaste
        self.keyboardType = keyboardType
        self.currencyFormatMaxDigits = currencyFormatMaxDigits
        self.maxLength = maxLength
        self.configuration = configuration
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            $isFirstResponder,
            $text,
            keyboardType,
            currencyFormatMaxDigits,
            maxLength
        )
    }
    
    func makeUIView(context: Context) -> UITextField {
        let view = PasteableTextField()
        view.text = text
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.keyboardType = keyboardType
        view.disablePaste = disablePaste
        configuration(view)
        
        view.delegate = context.coordinator
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

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        @Binding private var isFirstResponder: Bool
        
        let keyboardType: UIKeyboardType
        let currencyFormatMaxDigits: Int?
        let maxLength: Int?
        
        init(
            _ isFirstResponder: Binding<Bool>,
            _ text: Binding<String>,
            _ keyboardType: UIKeyboardType,
            _ currencyFormatMaxDigits: Int?,
            _ maxLength: Int?
        ) {
            self._isFirstResponder = isFirstResponder
            self._text = text
            self.keyboardType = keyboardType
            self.currencyFormatMaxDigits = currencyFormatMaxDigits
            self.maxLength = maxLength
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let currentText = textField.text,
                  var rangeInCurrent = Range(range, in: currentText)
            else { return false }

            let newText = currentText.replacingCharacters(in: rangeInCurrent, with: string).halfWidth
            
            if let maxLength = maxLength {
                guard lengthIsShorter(than: maxLength, newText)
                else { return false }
            }

            if let maxDigits = currencyFormatMaxDigits {
                if string.isEmpty && String(currentText[rangeInCurrent]) == "," {
                    rangeInCurrent = Range(NSRange(location: range.location - 1, length: range.length), in: currentText) ?? rangeInCurrent
                }
                
                var newText = currentText.replacingCharacters(in: rangeInCurrent, with: string).halfWidth
                
                guard !newText.isEmpty
                else {
                    self.text = newText
                    textField.text = newText

                    return false
                }
                
                guard !isMultipleDecimalPoints(newText) else { return false }
                guard !isEndWithDecimalPoint(newText) else {
                    self.text = String(newText.dropLast())
                    textField.text = newText

                    return false
                }
                guard !isAfterDecimalPointInputInProgress(newText, maxDigits:  maxDigits) else { return true }

                toCurrencyFormat(&newText, maxDigits: maxDigits)
                
                self.text = newText
                textField.remainCursor(to: newText)

                return false
            }

            self.text = newText
            return true
        }
        
        private func toCurrencyFormat(_ text: inout String, maxDigits: Int) {
            text = text.replacingOccurrences(of: ",", with: "")
            
            checkStartWithDecimalPoint(&text)
            
            if let amountString = Decimal(string: text)?.currencyFormatWithoutSymbol(maximumFractionDigits: maxDigits) {
                text = amountString
            }
        }
        
        private func lengthIsShorter(than max: Int, _ text: String) -> Bool {
            if text.count <= max {
                return true
            }
            else {
                return false
            }
        }
        
        private func isEndWithDecimalPoint(_ text: String) -> Bool {
            if text.last == "." {
                return true
            }
            else {
                return false
            }
        }
        
        private func isMultipleDecimalPoints(_ text: String) -> Bool {
            if text.filter({ $0 == "."}).count > 1 {
                return true
            }
            else {
                return false
            }
        }
        
        private func isAfterDecimalPointInputInProgress(_ text: String, maxDigits: Int) -> Bool {
            let splittedText = text.split(separator: ".")
            
            guard splittedText.count == 2 else { return false }
            
            if splittedText[1].contains(where: { $0 != "0" }) || splittedText[1].count == maxDigits {
                return false
            }
            else {
                return true
            }
        }
        
        private func checkStartWithDecimalPoint(_ text: inout  String) {
            if text.first == "." {
                text = "0" + text
            }
        }
        
        @objc func textEditEnd(_ sender: UITextField) {
            isFirstResponder = false
            
            if let senderText = sender.text, senderText != text {
                sender.text = text
            }
        }
    }
}
