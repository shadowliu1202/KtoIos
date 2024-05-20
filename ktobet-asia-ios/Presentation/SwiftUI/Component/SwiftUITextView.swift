import SwiftUI

struct SwiftUITextView: View {
    @State private var isInFocus = false
  
    @Binding private var text: String
  
    private let placeholder: String
    private let maxLength: Int?
  
    private let id = UUID()
  
    init(placeholder: String, text: Binding<String>, maxLength: Int? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
    }
  
    var body: some View {
        ZStack(alignment: .topLeading) {
            UIKitTextView(
                isInFocus: $isInFocus,
                text: $text,
                maxLength: maxLength,
                initConfiguration: { textView in
                    textView.font = UIFont(name: "PingFangSC-Regular", size: 14)
                    textView.textColor = .greyScaleWhite
                    textView.tintColor = .primaryDefault
                    textView.backgroundColor = .inputDefault
                    textView.cornerRadius = 8
                    textView.textContainer.lineFragmentPadding = 0
                    textView.textContainerInset = .zero
                    textView.textContainerInset = .init(top: 15, left: 15, bottom: 15, right: 15)
                    textView.autocapitalizationType = .none
                },
                updateConfiguration: { textView in
                    if isInFocus {
                        textView.text = text.isEmpty ? nil : text
                        textView.backgroundColor = .inputFocus
                    }
                    else {
                        textView.backgroundColor = .inputDefault
                    }
                })
                .onTapGesture {
                    DropDownList.notifyTopSideDetectListShouldCollapse(id: id)
                }
      
            Text(placeholder)
                .padding(15)
                .visibility(isInFocus || !text.isEmpty ? .gone : .visible)
                .localized(weight: .regular, size: 14, color: .textPrimary)
        }
    }
}

struct SwiftUITextView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUITextView(
            placeholder: "placeholder",
            text: .constant(""))
            .frame(height: 100)
    }
}
