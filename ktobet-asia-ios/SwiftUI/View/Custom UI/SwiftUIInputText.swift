
import SwiftUI

extension SwiftUIInputText {
    enum Identifier: String {
        case textField
        case ErrorHint
        case inputText
    }    
}

struct SwiftUIInputText: View {
    
    @State private var innerIsEditing: Bool = false
    @State private var showTextField: Bool = false
    @State private var showPassword: Bool = false

    @Binding var textFieldText: String
    @Binding var isEditing: Bool
    
    private let placeHolder: String
    private let errorText: String
    private let featureType: FeatureType
    private let keyboardType: UIKeyboardType
    private let currencyFormatMaxDigits: Int?
    private let maxLength: Int?

    private let disablePaste: Bool
    private let disableInput: Bool
    
    init(placeHolder: String,
         textFieldText: Binding<String>,
         errorText: String = "",
         featureType: FeatureType = .nil,
         keyboardType: UIKeyboardType = .default,
         currencyFormatMaxDigits: Int? = nil,
         maxLength: Int? = nil,
         disablePaste: Bool = false,
         disableInput: Bool = false,
         isEditing: Binding<Bool> = .constant(false)
    ) {
        self.placeHolder = placeHolder
        self._textFieldText = textFieldText
        self.errorText = errorText
        self.featureType = featureType
        self.keyboardType = keyboardType
        self.currencyFormatMaxDigits = currencyFormatMaxDigits
        self.maxLength = maxLength
        self.disablePaste = disablePaste
        self.disableInput = disableInput
        self._isEditing = isEditing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            inputText
                .overlay(
                    errorUnderline
                        .visibility(errorText.isEmpty ? .gone : .visible)
                )
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showTextField = true
                    }
                    
                    innerIsEditing = true
                }
            
            Text(errorText)
                .id(Identifier.ErrorHint.rawValue)
                .localized(weight: .regular, size: 12, color: .orangeFF8000)
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
        .onChange(of: innerIsEditing) { newValue in
            if isEditing != newValue {
                isEditing = newValue
            }
        }
        .onChange(of: isEditing) { newValue in
            if innerIsEditing != newValue {
                innerIsEditing = newValue
            }
        }
        .id(Identifier.inputText.rawValue)
    }
    
    private var inputText: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(placeHolder)
                    .font(.custom("PingFangSC-Regular", size: showTextField ? 12 : 14))
                    .foregroundColor(.from(.gray9B9B9B))
                    .padding(.top, showTextField ? 1 : 12)
                    .padding(.bottom, showTextField ? 0 : 10)
                
                UIKitTextField(
                    text: $textFieldText,
                    isFirstResponder: $innerIsEditing,
                    showPassword: $showPassword,
                    isPasswordType: featureType == .password,
                    disablePaste: disablePaste,
                    keyboardType: keyboardType,
                    currencyFormatMaxDigits: currencyFormatMaxDigits,
                    maxLength: maxLength,
                    configuration: { uiTextField in
                        uiTextField.font = UIFont(name: "PingFangSC", size: 16)
                        uiTextField.textColor = .white
                        uiTextField.tintColor = .redF20000
                        uiTextField.autocapitalizationType = .none
                    },
                    editingDidEnd: { text in
                        withAnimation(.easeOut(duration: 0.2)) {
                            showTextField = text.isEmpty ? false : true
                        }
                    }
                )
                .fixedSize(horizontal: false, vertical: true)
                .visibility(showTextField ? .visible : .gone)
                .disabled(disableInput)
                .id(Identifier.textField.rawValue)
                .overlay(
                    Text(textFieldText)
                        .localized(
                            weight: .regular,
                            size: 16,
                            color: .white
                        )
                        .visibility(disableInput ? .visible : .gone),
                    alignment: .leading 
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            
            featureButton(featureType)
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .padding(.horizontal, 15)
        .backgroundColor(innerIsEditing ? .gray454545 : .gray333333)
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func featureButton(_ type: FeatureType) -> some View {
        switch type {
        case .nil :
            EmptyView()
            
        case .password:
            eyeIcon
                .onTapGesture {
                    showPassword.toggle()
                }
            
        case .lock(let buttonOnTap):
            Image("Lock")
                .onTapGesture {
                    buttonOnTap()
                }
            
        case .other:
            LimitSpacer(24)
        }
    }
    
    @ViewBuilder
    private var eyeIcon: some View {
        if showPassword {
            Image("Eye-Show")
        } else {
            Image("Eye-Hide")
        }
    }
    
    private var errorUnderline: some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(.from(innerIsEditing ? .gray454545 : .gray333333))
                .frame(height: 10)
            
            Rectangle()
                .foregroundColor(.from(.orangeFF8000))
                .frame(height: 2)
        }
        .frame(maxHeight: .infinity ,alignment: .bottom)
        .animation(.easeOut(duration: 0.2), value: showTextField)
        .allowsHitTesting(false)
    }
}

extension SwiftUIInputText {
    enum FeatureType: Equatable {
        case `nil`
        case password
        case lock(() -> Void)
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
            featureType: .password
        )
        .previewLayout(.fixed(width: 315, height: 84))
    }
}
