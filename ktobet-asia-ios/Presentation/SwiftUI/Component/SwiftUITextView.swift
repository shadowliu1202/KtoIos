import SwiftUI

struct SwiftUITextView: View {
  @State var isInFocus = false
  
  @Binding var text: String
  
  var placeholder: String
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      UIKitTextView(
        isInFocus: $isInFocus,
        text: $text,
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
        })
      
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
      text: .constant(""),
      placeholder: "placeholder")
      .frame(height: 100)
  }
}
