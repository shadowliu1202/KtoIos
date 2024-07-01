import sharedbu
import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel

    @State private var isLoadedData = false
    let isForceChinese: Bool
    let onLogin: (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void
    let onResetPassword: () -> Void
    let onOtpLogin: () -> Void
    let toggleForceChinese: () -> Void

    init(
        viewModel: LoginViewModel,
        isForceChinese: Bool,
        onLogin: @escaping (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void,
        onResetPassword: @escaping () -> Void,
        onOTPLogin: @escaping () -> Void,
        toggleForceChinese: @escaping () -> Void)
    {
        self._viewModel = .init(wrappedValue: viewModel)
        self.isForceChinese = isForceChinese
        self.onLogin = onLogin
        self.onResetPassword = onResetPassword
        self.onOtpLogin = onOTPLogin
        self.toggleForceChinese = toggleForceChinese
    }

    var body: some View {
        ScrollView {
            #if DEBUG || QAT
                HStack {
                    Circle()
                        .fill(isForceChinese ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Spacer().frame(width: 8)
                    Text("切換中文")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { toggleForceChinese() }
            #endif
            PageContainer {
                VStack(spacing: 0) {
                    self.loginTitle()
                    LimitSpacer(30)
                    self.loginError(viewModel.getLoginErrorText())
                    self.loginInputTextField(
                        $viewModel.account,
                        viewModel.accountErrorText,
                        $viewModel.password,
                        viewModel.passwordErrorText,
                        $viewModel.isRememberMe,
                        accountOnChange: {
                            viewModel.checkAccountFormat()
                            viewModel.checkLoginInputFormat()
                        },
                        passwordOnChange: {
                            viewModel.checkPasswordFormat()
                            viewModel.checkLoginInputFormat()
                        })
                    self.captcha(
                        $viewModel.captchaText,
                        viewModel.captchaErrorText,
                        viewModel.captchaImage,
                        getCaptchaOnTap: viewModel.getCaptchaImage,
                        captchaTextOnChange: {
                            viewModel.checkCaptchaFormat()
                            viewModel.checkLoginInputFormat()
                        })
                    LimitSpacer(40)
                    self.loginButton(viewModel.countDownSecond, viewModel.disableLoginButton) {
                        viewModel.login(callBack: onLogin)
                    }
                    LimitSpacer(24)
                    self.resetPassword(onTapped: onResetPassword)
                    LimitSpacer(30)
                    HStack {
                        Separator()
                        Text(Localize.string("common_or"))
                            .localized(weight: .regular, size: 14, color: .textPrimary)
                            .padding(.horizontal, 30)
                        Separator()
                    }.frame(maxWidth: .infinity)
                    LimitSpacer(30)
                    otpLoginButton(onPressed: onOtpLogin)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
            }
        }
        .pageBackgroundColor(.greyScaleDefault)
        .environment(\.playerLocale, viewModel.getSupportLocale())
        .onAppear {
            if !isLoadedData {
                viewModel.initRememberAccount()
                viewModel.checkNeedCaptcha()
                viewModel.checkNeedCountDown()
                isLoadedData = true
            }
        }
        .onAppear {
            viewModel.refreshUI()
        }
    }

    @ViewBuilder
    private func loginTitle() -> some View {
        Text(Localize.string("common_login"))
            .localized(weight: .semibold, size: 24, color: .textPrimary)
    }

    @ViewBuilder
    private func loginError(_ text: String?) -> some View {
        Group {
            VerifiedAlert(text ?? "")

            LimitSpacer(12)
        }
        .visibility(text == nil ? .gone : .visible)
    }

    @ViewBuilder
    private func loginInputTextField(
        _ accountText: Binding<String>,
        _ accountErrorText: String,
        _ passwordText: Binding<String>,
        _ passwordErrorText: String,
        _ isRememberMe: Binding<Bool>,
        accountOnChange: @escaping () -> Void,
        passwordOnChange: @escaping () -> Void)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUIInputText(
                placeHolder: Localize.string("login_account_identity"),
                textFieldText: accountText,
                errorText: accountErrorText,
                textFieldType: GeneralType(
                    regex: .email,
                    keyboardType: .emailAddress))

            SwiftUIInputText(
                placeHolder: Localize.string("common_password"),
                textFieldText: passwordText,
                errorText: passwordErrorText,
                featureType: .password,
                textFieldType: GeneralType(regex: .all))

            HStack(spacing: 4) {
                if isRememberMe.wrappedValue {
                    Image("isRememberMe")
                }
                else {
                    Circle()
                        .strokeBorder(Color.from(.textPrimary), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .padding(1)
                }

                Text(Localize.string("login_account_remember_me"))
                    .localized(weight: .regular, size: 12, color: .textPrimary)
            }
            .onTapGesture {
                isRememberMe.wrappedValue.toggle()
            }
        }
        .onChange(of: accountText.wrappedValue) { _ in
            accountOnChange()
        }
        .onChange(of: passwordText.wrappedValue) { _ in
            passwordOnChange()
        }
    }

    @ViewBuilder
    private func captcha(
        _ text: Binding<String>,
        _ errorText: String,
        _ image: UIImage?,
        getCaptchaOnTap: @escaping () -> Void,
        captchaTextOnChange: @escaping () -> Void)
        -> some View
    {
        Group {
            LimitSpacer(30)
            VStack(spacing: 12) {
                VerifiedAlert(key: "login_enter_captcha_to_prceed")
                SwiftUIInputText(
                    placeHolder: Localize.string("login_captcha"),
                    textFieldText: text,
                    errorText: errorText,
                    textFieldType: GeneralType(regex: .numberAndEnglish))
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 32)
                Text(Localize.string("login_captcha_new"))
                    .localized(weight: .medium, size: 14, color: .primaryDefault)
                    .onTapGesture {
                        getCaptchaOnTap()
                    }
            }
        }
        .visibility(image == nil ? .gone : .visible)
        .onChange(of: text.wrappedValue) { _ in
            captchaTextOnChange()
        }
        .accessibilityIdentifier("captcha")
    }

    @ViewBuilder
    private func loginButton(_ countDownSecond: Int?, _ disabled: Bool, onPressed: @escaping () -> Void) -> some View {
        Button(
            action: { onPressed() },
            label: {
                HStack(spacing: 0) {
                    Text(Localize.string("common_login"))
                    Text("(\(countDownSecond ?? 0))")
                        .visibility(countDownSecond == nil ? .gone : .visible)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            })
            .buttonStyle(.fill)
            .localized(weight: .regular, size: 16)
            .disabled(disabled)
    }

    @ViewBuilder
    private func resetPassword(onTapped: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(Localize.string("login_tips_1"))
                .foregroundColor(.from(.textPrimary))
            Text(" ")
            Text(Localize.string("login_tips_1_highlight"))
                .foregroundColor(.from(.primaryDefault))
                .onTapGesture {
                    onTapped()
                }
        }
        .localized(weight: .regular, size: 14)
    }

    @ViewBuilder
    private func otpLoginButton(onPressed: @escaping () -> Void) -> some View {
        Button(
            action: { onPressed() },
            label: {
                Text(Localize.string("login_by_otp"))
                    .foregroundColor(.from(.primaryDefault))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.from(.textPrimary), lineWidth: 0.5))
            })
            .localized(weight: .regular, size: 16)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(
            viewModel: Injectable.resolveWrapper(LoginViewModel.self),
            isForceChinese: false,
            onLogin: { _, _ in },
            onResetPassword: { },
            onOTPLogin: { },
            toggleForceChinese: { })
    }
}
