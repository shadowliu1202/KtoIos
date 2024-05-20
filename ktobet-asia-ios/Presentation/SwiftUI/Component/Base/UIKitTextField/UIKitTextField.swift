import SwiftUI

struct UIKitTextField: UIViewRepresentable {
    @State private var oldText = ""
  
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var showPassword: Bool
  
    private let isPasswordType: Bool
    private let textFieldType: any TextFieldType

    private var initConfiguration = { (_: UITextField) in }
    private var updateConfiguration = { (_: UITextField) in }

    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        showPassword: Binding<Bool>,
        isPasswordType: Bool,
        textFieldType: some TextFieldType,
        initConfiguration: @escaping (UITextField) -> Void = { (_: UITextField) in },
        updateConfiguration: @escaping (UITextField) -> Void = { (_: UITextField) in })
    {
        oldText = text.wrappedValue
    
        self._text = text
        self._isFirstResponder = isFirstResponder
        self._showPassword = showPassword

        self.isPasswordType = isPasswordType
        self.textFieldType = textFieldType
        self.initConfiguration = initConfiguration
        self.updateConfiguration = updateConfiguration
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let view = PasteableTextField()
        view.delegate = context.coordinator
        view.disableAutoFillOnIos16()
        view.text = text
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        initConfiguration(view)
        textFieldType.functionalConfig(view)

        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditChanged), for: .editingChanged)
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditEnd), for: .editingDidEnd)
        view.addTarget(context.coordinator, action: #selector(context.coordinator.textEditEnd), for: .editingDidEndOnExit)

        return view
    }

    func updateUIView(_ uiView: UITextField, context _: Context) {
        uiView.isSecureTextEntry = isPasswordType && !showPassword
        uiView.disableAutoFillOnIos16()
        uiView.text = text
        updateConfiguration(uiView)

        DispatchQueue.main.async {
            if isFirstResponder {
                uiView.becomeFirstResponder()
            }
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: UIKitTextField
    
        init(_ parent: UIKitTextField) {
            self.parent = parent
      
            super.init()
        }

        @objc
        func textEditChanged(_ sender: PasteableTextField) {
            if
                let markedRange = sender.markedTextRange,
                sender.position(from: markedRange.start, offset: 0) != nil
            {
                return
            }

            guard let newText = sender.text?.halfWidth else { return }

            parent.textFieldType.format(parent.oldText, newText) {
                parent.text = $0
                sender.remainCursor(to: $0)
                parent.oldText = $0
            }
        }

        @objc
        func textEditEnd(_: UITextField) {
            parent.isFirstResponder = false
            parent.textFieldType.onEditEnd(parent._text)
        }
    }
}
