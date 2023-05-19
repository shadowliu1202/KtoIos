import SwiftUI

struct UIKitTextField: UIViewRepresentable {
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
    self._text = text
    self._isFirstResponder = isFirstResponder
    self._showPassword = showPassword

    self.isPasswordType = isPasswordType
    self.textFieldType = textFieldType
    self.initConfiguration = initConfiguration
    self.updateConfiguration = updateConfiguration
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      $text,
      $isFirstResponder,
      textFieldType)
  }

  func makeUIView(context: Context) -> UITextField {
    let view = PasteableTextField()
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

  class Coordinator: NSObject {
    @Binding private var text: String
    @Binding private var isFirstResponder: Bool

    private let textFieldType: any TextFieldType

    lazy var oldText: String = text

    init(
      _ text: Binding<String>,
      _ isFirstResponder: Binding<Bool>,
      _ textFieldType: some TextFieldType)
    {
      self._text = text
      self._isFirstResponder = isFirstResponder
      self.textFieldType = textFieldType
    }

    @objc
    func textEditChanged(_ sender: UITextField) {
      if
        let markedRange = sender.markedTextRange,
        sender.position(from: markedRange.start, offset: 0) != nil
      {
        return
      }

      guard let newText = sender.text?.halfWidth else { return }

      textFieldType.format(oldText, newText) {
        $text.wrappedValue = $0
        sender.remainCursor(to: $0)
        oldText = $0
      }
    }

    @objc
    func textEditEnd(_: UITextField) {
      isFirstResponder = false

      textFieldType.onEditEnd($text)
    }
  }
}
