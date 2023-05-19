import SwiftUI

struct OTPVerifyTextField: View {
  static let VNMobileLength = 4

  @State private var isEditing = false

  @Binding private var otpCode: String

  private let length: Int

  init(_ otpCode: Binding<String>, length: Int) {
    self._otpCode = otpCode
    self.length = length
  }

  var body: some View {
    ZStack {
      UIKitTextField(
        text: $otpCode,
        isFirstResponder: $isEditing,
        showPassword: .constant(false),
        isPasswordType: false,
        textFieldType: GeneralType(
          regex: .number,
          keyboardType: .numberPad,
          disablePaste: true,
          maxLength: length),
        initConfiguration: { textField in
          textField.tintColor = .clear
          textField.textColor = .clear
        })
        .frame(width: 1, height: 1)

      HStack(spacing: length == OTPVerifyTextField.VNMobileLength ? 12 : 0) {
        ForEach(0..<length, id: \.self) { index in
          let isLast = index == (0..<length).last

          codeCell(
            text: index < otpCode.count
              ? String(otpCode[otpCode.index(
                otpCode.startIndex,
                offsetBy: index)])
              : "",
            onFocus: (index == otpCode.count) && isEditing,
            onInputFinished: isLast && otpCode.count == length && isEditing)

          if length != OTPVerifyTextField.VNMobileLength {
            Spacer()
              .visibility(isLast ? .gone : .visible)
          }
        }
      }
      .contentShape(Rectangle())
      .onTapGesture {
        isEditing = true
      }
    }
  }

  func codeCell(text: String, onFocus: Bool, onInputFinished: Bool) -> some View {
    RoundedRectangle(cornerRadius: 6)
      .fill(Color.from(.inputDefault))
      .frame(width: 40, height: 40)
      .overlay(
        Text(text)
          .localized(weight: .semibold, size: 18, color: .greyScaleWhite))
      .overlay(
        BlinkingCursor()
          .padding(10)
          .visibility(onFocus || onInputFinished ? .visible : .gone),
        alignment: onInputFinished ? .trailing : .leading)
  }
}

extension OTPVerifyTextField {
  struct BlinkingCursor: View {
    @State private var opacity: Double = 1

    var body: some View {
      Rectangle()
        .fill(Color.from(.primaryDefault))
        .frame(width: 2, height: 20).opacity(opacity)
        .onAppear {
          withAnimation(
            .easeOut(duration: 0.65)
              .repeatForever(autoreverses: true))
          {
            opacity = 0
          }
        }
    }
  }
}

struct OTPVerifyTextField_Previews: PreviewProvider {
  struct Preview: View {
    @State private var otpCode = "505"

    var body: some View {
      OTPVerifyTextField($otpCode, length: 6)
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageBackgroundColor(.greyScaleDefault)
    }
  }

  static var previews: some View {
    Preview()
  }
}
