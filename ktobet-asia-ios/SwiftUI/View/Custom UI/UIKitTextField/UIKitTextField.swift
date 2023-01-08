
import SwiftUI

struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var showPassword: Bool

    private let isPasswordType: Bool
    private let textFieldType: any TextFieldType
    
    private var configuration = { (uiTextField: UITextField) in }
    
    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        showPassword: Binding<Bool>,
        isPasswordType: Bool,
        textFieldType: some TextFieldType,
        configuration: @escaping (UITextField) -> () = { (uiTextField: UITextField) in }
    ) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self._showPassword = showPassword
        
        self.isPasswordType = isPasswordType
        self.textFieldType = textFieldType
        self.configuration = configuration
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            $text,
            $isFirstResponder,
            textFieldType
        )
    }
    
    func makeUIView(context: Context) -> UITextField {
        let view = PasteableTextField()
        view.text = text
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        configuration(view)
        textFieldType.functionalConfig(view)
        
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditChanged), for: .editingChanged)
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditEnd), for: .editingDidEnd)
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditEnd), for: .editingDidEndOnExit)
        
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.isSecureTextEntry = isPasswordType && !showPassword
        uiView.text = text
        
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

    class Coordinator: NSObject {
        @Binding private var text: String
        @Binding private var isFirstResponder: Bool
        
        private let textFieldType: any TextFieldType
        
        lazy var oldText: String = text
        
        init(
            _ text: Binding<String>,
            _ isFirstResponder: Binding<Bool>,
            _ textFieldType: some TextFieldType
        ) {
            self._text = text
            self._isFirstResponder = isFirstResponder
            self.textFieldType = textFieldType
        }
        
        @objc func textEditChanged(_ sender: UITextField) {
            if let markedRange = sender.markedTextRange,
               sender.position(from: markedRange.start, offset: 0) != nil {
                return
            }
            
            guard let newText = sender.text?.halfWidth else { return }
            
            textFieldType.format(oldText, newText, $text)
            sender.remainCursor(to: text)
            oldText = text
        }
        
        @objc func textEditEnd(_ sender: UITextField) {
            isFirstResponder = false
            
            textFieldType.onEditEnd($text)
        }
    }
}
