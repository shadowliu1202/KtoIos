
import SwiftUI

struct SwiftUIInputText: View {
    @State private var isEditing: Bool = false
    @State private var showTextField: Bool = false
    @State private var showPassword: Bool = false

    @Binding var textFieldText: String
    
    let placeHolder: String
    let errorText: String?
    let isPasswordType: Bool
    let keyboardType: UIKeyboardType
    
    init(placeHolder: String, textFieldText: Binding<String>, errorText: String? = nil, isPasswordType: Bool = false, keyboardType: UIKeyboardType = .default) {
        self.placeHolder = placeHolder
        self._textFieldText = textFieldText
        self.errorText = errorText
        self.isPasswordType = isPasswordType
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            self.inputText()
                .overlay(
                    errorUnderline()
                        .visibility(errorText != nil ? .visible : .gone)
                )
            self.errorHint()
                .visibility(errorText == nil ? .gone : .visible)
        }
    }
    
    @ViewBuilder
    private func inputText() -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(placeHolder)
                    .font(.custom("PingFangSC-Regular", size: showTextField ? 12 : 14))
                    .foregroundColor(.primaryGray)
                    .padding(.top, showTextField ? 1 : 12)
                    .padding(.bottom, showTextField ? 0 : 10)
                
                UIKitTextField(text: $textFieldText, isFirstResponder: $isEditing, showPassword: $showPassword, isPasswordType: isPasswordType, keyboardType: keyboardType) { uiTextField in
                    uiTextField.font = UIFont(name: "PingFangSC", size: 16)
                    uiTextField.textColor = .white
                    uiTextField.tintColor = .primaryRed
                    uiTextField.autocapitalizationType = .none
                } editingDidEnd: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showTextField = textFieldText.isEmpty ? false : true
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
            self.eyeIcon()
                .onTapGesture {
                    showPassword.toggle()
                }
                .visibility(isPasswordType ? .visible : .gone)
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
        .padding(.horizontal, 12)
        .backgroundColor(isEditing ? .inputFocus : .inputDefault)
        .cornerRadius(8)
        .onAppear {
            if !textFieldText.isEmpty && !showTextField {
                showTextField = true
            }
        }
        .onChange(of: textFieldText) { _ in
            if !textFieldText.isEmpty && !showTextField {
                showTextField = true
            }
        }
    }
    
    @ViewBuilder
    private func eyeIcon() -> some View {
        if showPassword {
            Image("Eye-Show")
        } else {
            Image("Eye-Hide")
        }
    }
    
    @ViewBuilder
    private func errorUnderline() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .foregroundColor(isEditing ? .inputFocus : .inputDefault)
                .frame(height: 10)
            
            Rectangle()
                .foregroundColor(.alert)
                .frame(height: 2)
        }
        .frame(maxHeight: .infinity ,alignment: .bottom)
        .animation(.easeOut(duration: 0.2), value: showTextField)
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func errorHint() -> some View {
        Text(errorText ?? "")
            .customizedFont(fontWeight: .regular, size: 12, color: .alert)
    }
}

struct SwiftUIInputText_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIInputText(placeHolder: "手机/电子邮箱", textFieldText: .constant(""), errorText: "请输入正确的电子邮箱。", isPasswordType: true)
            .previewLayout(.fixed(width: 315, height: 84))
    }
}
