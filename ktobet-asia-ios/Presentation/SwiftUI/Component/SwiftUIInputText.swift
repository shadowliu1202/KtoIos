
import SwiftUI

extension SwiftUIInputText {
  enum Identifier: String {
    case textField
    case errorHint
    case inputText
    case arrow
    case wholeInputView
  }
}

struct SwiftUIInputText: View {
  @State private var syncIsFocus = false
  @State private var showTextField = false
  @State private var showPassword = false

  @State private var textFieldHight: CGFloat?

  @Binding var textFieldText: String
  @Binding var isFocus: Bool

  private let id: UUID

  private let placeHolder: String
  private let errorText: String
  private let featureType: FeatureType
  private let textFieldType: any TextFieldType

  private let disableInput: Bool

  private let onInputTextTap: (() -> Void)?

  init(
    id: UUID? = nil,
    placeHolder: String,
    textFieldText: Binding<String>,
    errorText: String = "",
    featureType: FeatureType = .nil,
    textFieldType: some TextFieldType,
    disableInput: Bool = false,
    onInputTextTap: (() -> Void)? = nil,
    isFocus: Binding<Bool> = .constant(false))
  {
    self.id = id ?? UUID()
    self.placeHolder = placeHolder
    self._textFieldText = textFieldText
    self.errorText = errorText
    self.featureType = featureType
    self.textFieldType = textFieldType
    self.disableInput = disableInput
    self.onInputTextTap = onInputTextTap
    self._isFocus = isFocus
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      inputText
        .overlay(
          errorUnderline
            .visibility(errorText.isEmpty ? .gone : .visible))
        .id(Identifier.inputText.rawValue)
        .onTapGesture {
          withAnimation(.easeOut(duration: 0.2)) {
            showTextField = true
          }

          DropDownList.notifyTopSideDetectListShouldCollapse(id: id)
          syncIsFocus = true

          onInputTextTap?()
        }

      Text(errorText)
        .localized(weight: .regular, size: 12, color: .alert)
        .id(SwiftUIInputText.Identifier.errorHint.rawValue)
        .visibility(errorText.isEmpty ? .gone : .visible)
    }
    .onAppear {
      if !textFieldText.isEmpty {
        showTextField = true
      }
    }
    .onChange(of: textFieldText) { text in
      if !text.isEmpty {
        showTextField = true
      }
    }
    .onChange(of: syncIsFocus) { newValue in
      if isFocus != newValue {
        isFocus = newValue
      }

      if !newValue {
        withAnimation(.easeOut(duration: 0.2)) {
          showTextField = textFieldText.isEmpty ? false : true
        }
      }
    }
    .onChange(of: isFocus) { newValue in
      if syncIsFocus != newValue {
        syncIsFocus = newValue
      }
    }
    .id(Identifier.wholeInputView.rawValue)
  }

  private var inputText: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text(placeHolder)
          .font(.custom("PingFangSC-Regular", size: showTextField ? 12 : 14))
          .foregroundColor(.from(.textPrimary))
          .padding(.top, showTextField ? 1 : 12)
          .padding(.bottom, showTextField ? 0 : 10)

        UIKitTextField(
          text: $textFieldText,
          isFirstResponder: $syncIsFocus,
          showPassword: $showPassword,
          isPasswordType: featureType == .password,
          textFieldType: textFieldType,
          initConfiguration: { uiTextField in
            uiTextField.font = UIFont(name: "PingFangSC", size: 16)
            uiTextField.textColor = .white
            uiTextField.tintColor = .primaryDefault
            uiTextField.autocapitalizationType = .none
          })
          .fixedSize(horizontal: false, vertical: true)
          .visibility(showTextField ? .visible : .gone)
          .disabled(disableInput)
          .id(SwiftUIInputText.Identifier.textField.rawValue)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .frameDetecter(onAppear: { frame in
        textFieldHight = frame.height
      })

      featureButton(featureType)
    }
    .padding(.top, 8)
    .padding(.bottom, 10)
    .padding(.horizontal, 15)
    .backgroundColor(syncIsFocus ? .inputFocus : .inputDefault)
    .cornerRadius(8)
  }

  @ViewBuilder
  private func featureButton(_ type: FeatureType) -> some View {
    switch type {
    case .nil:
      EmptyView()

    case .password:
      eyeIcon
        .onTapGesture {
          showPassword.toggle()
        }

    case .lock:
      Image("Lock")

    case .qrCode(let buttonOnTap):
      HStack(spacing: 8) {
        Rectangle()
          .foregroundColor(.from(.textPrimary))
          .frame(width: 0.5, height: textFieldHight)

        Image("QRcode")
          .onTapGesture {
            buttonOnTap()
          }
      }

    case .dropDownArrow:
      Image("DropDown")
        .rotationEffect(
          .degrees(syncIsFocus ? 180 : 0),
          anchor: .center)
        .id(Identifier.arrow.rawValue)

    case .other:
      LimitSpacer(24)
    }
  }

  @ViewBuilder private var eyeIcon: some View {
    if showPassword {
      Image("Eye-Show")
    }
    else {
      Image("Eye-Hide")
    }
  }

  private var errorUnderline: some View {
    VStack(spacing: 0) {
      Rectangle()
        .foregroundColor(.from(syncIsFocus ? .inputFocus : .inputDefault))
        .frame(height: 5)

      Rectangle()
        .foregroundColor(.from(.alert))
        .frame(height: 2)
    }
    .frame(maxHeight: .infinity, alignment: .bottom)
    .animation(.easeOut(duration: 0.2), value: showTextField)
    .allowsHitTesting(false)
  }
}

extension SwiftUIInputText {
  enum FeatureType: Equatable {
    case `nil`
    case password
    case lock
    case qrCode(() -> Void)
    case dropDownArrow
    case other

    static func == (lhs: SwiftUIInputText.FeatureType, rhs: SwiftUIInputText.FeatureType) -> Bool {
      switch (lhs, rhs) {
      case (.password, .password):
        return true
      default:
        return false
      }
    }
  }
}

struct SwiftUIInputText_Previews: PreviewProvider {
  static var previews: some View {
    SwiftUIInputText(
      placeHolder: "手机/电子邮箱",
      textFieldText: .constant(""),
      errorText: "请输入正确的电子邮箱。",
      featureType: .password,
      textFieldType: GeneralType(regex: .all))
      .previewLayout(.fixed(width: 315, height: 84))
  }
}
