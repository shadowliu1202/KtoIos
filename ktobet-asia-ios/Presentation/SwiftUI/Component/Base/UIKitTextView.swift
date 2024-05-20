import SwiftUI

struct UIKitTextView: UIViewRepresentable {
    @Binding var isInFocus: Bool
    @Binding var text: String
  
    private let maxLength: Int?
    private let initConfiguration: (UITextView) -> Void
    private let updateConfiguration: (UITextView) -> Void
  
    init(
        isInFocus: Binding<Bool>,
        text: Binding<String>,
        maxLength: Int? = nil,
        initConfiguration: @escaping (UITextView) -> Void = { (_: UITextView) in },
        updateConfiguration: @escaping (UITextView) -> Void = { (_: UITextView) in })
    {
        self._isInFocus = isInFocus
        self._text = text
        self.maxLength = maxLength
        self.initConfiguration = initConfiguration
        self.updateConfiguration = updateConfiguration
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
      
        initConfiguration(textView)
    
        return textView
    }

    func updateUIView(_ uiView: UITextView, context _: Context) {
        uiView.text = text
        updateConfiguration(uiView)
    }
  
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: UIKitTextView
    
        init(_ parent: UIKitTextView) {
            self.parent = parent
        }
    
        func textViewDidChange(_ textView: UITextView) {
            if textView.markedTextRange == nil {
                parent.text = textView.text
            }
        }
    
        func textViewDidBeginEditing(_: UITextView) {
            parent.isInFocus = true
        }
    
        func textViewDidEndEditing(_: UITextView) {
            if parent.isInFocus {
                parent.isInFocus = false
            }
        }
    
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let maxLength = parent.maxLength else { return true }
      
            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            
            let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
            
            return updatedText.count <= maxLength
        }
    }
}

struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        UIKitTextView(isInFocus: .constant(false), text: .constant("text"))
            .frame(height: 100)
    }
}
