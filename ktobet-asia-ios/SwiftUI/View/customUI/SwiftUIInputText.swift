
import SwiftUI

struct SwiftUIInputText: View {
    enum Identifier: String {
        case ErrorHint
    }
    
    @State private var isEditing: Bool = false
    @State private var showTextField: Bool = false
    @State private var showPassword: Bool = false

    @Binding var textFieldText: String
    
    let placeHolder: String
    let errorText: String?
    let isPasswordType: Bool
    let disablePaste: Bool
    let keyboardType: UIKeyboardType
    
    init(placeHolder: String, textFieldText: Binding<String>, errorText: String? = nil, isPasswordType: Bool = false, disablePaste: Bool = false, keyboardType: UIKeyboardType = .default) {
        self.placeHolder = placeHolder
        self._textFieldText = textFieldText
        self.errorText = errorText
        self.isPasswordType = isPasswordType
        self.disablePaste = disablePaste
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            inputText
                .overlay(
                    errorUnderline
                        .visibility(errorText == nil ? .gone : .visible)
                )
            
            Text(errorText ?? "")
                .id(Identifier.ErrorHint.rawValue)
                .localized(weight: .regular, size: 12, color: .orangeFF8000)
                .visibility(errorText == nil ? .gone : .visible)
        }
        .onAppear {
            if !textFieldText.isEmpty {
                showTextField = true
            }
        }
    }
    
    private var inputText: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(placeHolder)
                    .font(.custom("PingFangSC-Regular", size: showTextField ? 12 : 14))
                    .foregroundColor(.from(.gray9B9B9B))
                    .padding(.top, showTextField ? 1 : 12)
                    .padding(.bottom, showTextField ? 0 : 10)
                UIKitTextField(text: $textFieldText, isFirstResponder: $isEditing, showPassword: $showPassword, isPasswordType: isPasswordType, disablePaste: disablePaste, keyboardType: keyboardType) { uiTextField in
                    uiTextField.font = UIFont(name: "PingFangSC", size: 16)
                    uiTextField.textColor = .white
                    uiTextField.tintColor = .redF20000
                    uiTextField.autocapitalizationType = .none
                } editingDidEnd: { text in
                    withAnimation(.easeOut(duration: 0.2)) {
                        showTextField = text.isEmpty ? false : true
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .visibility(showTextField ? .visible : .gone)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) {
                    showTextField = true
                }
                
                isEditing = true
            }
            
            eyeIcon
                .onTapGesture {
                    showPassword.toggle()
                }
                .visibility(isPasswordType ? .visible : .gone)
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .padding(.horizontal, 12)
        .backgroundColor(isEditing ? .gray454545 : .gray333333)
        .cornerRadius(8)
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
                .foregroundColor(.from(isEditing ? .gray454545 : .gray333333))
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

struct SwiftUIInputText_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIInputText(placeHolder: "手机/电子邮箱", textFieldText: .constant(""), errorText: "请输入正确的电子邮箱。", isPasswordType: true)
            .previewLayout(.fixed(width: 315, height: 84))
    }
}
