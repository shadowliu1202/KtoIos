import Foundation
import SwiftUI

struct PasswordConfirmView: View {
    @State private var isPasswordVisible = false
    @Binding private var password: String
    @Binding private var passwordConfirm: String
    @FocusState private var isFocus: Bool

    private var errorMessage: String?

    init(password: Binding<String>, passwordConfirm: Binding<String>, errorMessage: String?) {
        _password = password
        _passwordConfirm = passwordConfirm
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let showErrorMessage = errorMessage?.isNotEmpty ?? false
            VStack(spacing: 0) {
                PasswordField(
                    key: "common_password",
                    isPasswordVisible: $isPasswordVisible,
                    password: $password,
                    visibilityToggle: { isPasswordVisible.toggle() }
                )
                .frame(maxHeight: .infinity)

                Separator(color: .textPrimary, lineWidth: 0.5)

                PasswordField(
                    key: "common_password_2",
                    isPasswordVisible: $isPasswordVisible,
                    password: $passwordConfirm,
                    visibilityToggle: nil
                )
                .frame(maxHeight: .infinity)
            }
            .frame(height: 120, alignment: .topLeading)
            .padding(.horizontal, 15)
            .background {
                RoundCornerRectangle(cornerRadius: 8, corner: showErrorMessage ? [.topLeft, .topRight] : .allCorners)
                    .fill(isFocus ? .inputFocus : .inputDefault)
            }
            .focused($isFocus)

            if showErrorMessage, let message = errorMessage {
                Separator(color: .alert, lineWidth: 2)
                LimitSpacer(6)
                Text(message).localized(weight: .regular, size: 12, color: .alert)
            }
        }
    }

    private struct PasswordField: View {
        let key: LocalizedStringKey
        @Binding var isPasswordVisible: Bool
        @Binding var password: String
        @FocusState private var isFocus: Bool
        let visibilityToggle: (() -> Void)?
        var body: some View {
            ZStack(alignment: .topLeading) {
                let shrinkLabel = isFocus || password.isNotEmpty
                let textSize: CGFloat = shrinkLabel ? 12 : 14
                let labelOffset: CGFloat = shrinkLabel ? -12 : 0
                let fieldOffset: CGFloat = shrinkLabel ? 10 : 0
                Text(key)
                    .localized(weight: .regular, size: textSize, color: .textPrimary)
                    .offset(y: labelOffset)
                    .animation(.spring(duration: 0.2), value: shrinkLabel)
                HStack(spacing: 0) {
                    inputField()
                        .localized(weight: .regular, size: 16, color: .white)
                        .offset(y: fieldOffset)
                        .animation(.spring(duration: 0.2), value: shrinkLabel)
                        .foregroundStyle(.greyScaleWhite)
                        .focused($isFocus)
                        .accentColor(.primaryDefault)

                    if let action = visibilityToggle {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundStyle(.textPrimary)
                            .onTapGesture { action() }
                    }
                }
            }
        }

        @ViewBuilder
        private func inputField() -> some View {
            if isPasswordVisible {
                TextField(text: $password) {}
            } else {
                SecureField(text: $password, label: {})
            }
        }
    }
}
