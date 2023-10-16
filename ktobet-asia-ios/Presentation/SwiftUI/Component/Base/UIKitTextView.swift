import SwiftUI

struct UIKitTextView: UIViewRepresentable {
  @Binding var isInFocus: Bool
  @Binding var text: String
  
  private var initConfiguration = { (_: UITextView) in }
  
  init(
    isInFocus: Binding<Bool>,
    text: Binding<String>,
    initConfiguration: @escaping (UITextView) -> Void = { (_: UITextView) in })
  {
    self._isInFocus = isInFocus
    self._text = text
    self.initConfiguration = initConfiguration
  }

  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView()
    textView.delegate = context.coordinator
      
    initConfiguration(textView)
    
    return textView
  }

  func updateUIView(_ uiView: UITextView, context _: Context) {
    if isInFocus {
      uiView.text = text.isEmpty ? nil : text
      uiView.backgroundColor = .inputFocus
    }
    else {
      uiView.backgroundColor = .inputDefault
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator($text, $isInFocus)
  }

  class Coordinator: NSObject, UITextViewDelegate {
    var isInFocus: Binding<Bool>
    var text: Binding<String>

    init(_ text: Binding<String>, _ isInFocus: Binding<Bool>) {
      self.text = text
      self.isInFocus = isInFocus
    }
    
    func textViewDidChange(_ textView: UITextView) {
      text.wrappedValue = textView.text
    }
    
    func textViewDidBeginEditing(_: UITextView) {
      isInFocus.wrappedValue = true
    }
    
    func textViewDidEndEditing(_: UITextView) {
      isInFocus.wrappedValue = false
    }
  }
}

struct TextView_Previews: PreviewProvider {
  static var previews: some View {
    UIKitTextView(isInFocus: .constant(false), text: .constant("text"))
      .frame(height: 100)
  }
}
