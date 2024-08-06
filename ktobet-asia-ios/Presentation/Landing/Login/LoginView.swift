import sharedbu
import SwiftUI

struct LoginView: View {
    @Environment(\.startManuelUpdate) private var startManuelUpdate
    @Environment(\.showDialog) var showDialog
    @StateObject var viewModel: LoginViewModel
    @State private var isLoadedData = false
    let isForceChinese: Bool
    let onLogin: (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void
    let onOtpLogin: () -> Void
    let toggleForceChinese: () -> Void

    @State private var moveToRegister: Bool = false

    init(
        viewModel: LoginViewModel,
        isForceChinese: Bool,
        onLogin: @escaping (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void,
        onOTPLogin: @escaping () -> Void,
        toggleForceChinese: @escaping () -> Void
    ) {
        _viewModel = .init(wrappedValue: viewModel)
        self.isForceChinese = isForceChinese
        self.onLogin = onLogin
        onOtpLogin = onOTPLogin
        self.toggleForceChinese = toggleForceChinese
    }

    private func manuelUpdate() -> ItemViews {
        .custom(NavigationItem<AnyView>(text: Localize.string("update_title"), action: { startManuelUpdate() }))
    }

    private func register() -> ItemViews {
        .custom(NavigationItem<AnyView>(
            text: Localize.string("common_register"),
            action: {
                switch onEnum(of: viewModel.getSupportLocale()) {
                case .china:
                    #if QAT
                        moveToRegister = true
                    #else
                        showDialog(info: .init(
                            title: Localize.string("common_tip_cn_down_title_warm"),
                            message: Localize.string("common_cn_service_down"),
                            confirm: { moveToRegister = true },
                            confirmText: Localize.string("common_cn_down_confirm")
                        ))
                    #endif
                case .vietnam:
                    moveToRegister = true
                }
            }
        ))
    }

    var body: some View {
        LandingViewScaffold(navItem: .empty(), items: [manuelUpdate(), .cs(), register()]) {
            ZStack(alignment: .topLeading) {
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
                    .zIndex(1)
                #endif

                PageContainer(scrollable: true) {
                    VStack(spacing: 0) {
                        loginTitle()
                        LimitSpacer(30)
                        loginError(viewModel.getLoginErrorText())
                        loginInputTextField(
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
                            }
                        )
                        captcha(
                            $viewModel.captchaText,
                            viewModel.captchaErrorText,
                            viewModel.captchaImage,
                            getCaptchaOnTap: viewModel.getCaptchaImage,
                            captchaTextOnChange: {
                                viewModel.checkCaptchaFormat()
                                viewModel.checkLoginInputFormat()
                            }
                        )
                        LimitSpacer(40)
                        loginButton(viewModel.countDownSecond, viewModel.disableLoginButton) {
                            viewModel.login(callBack: onLogin)
                        }
                        LimitSpacer(24)
                        resetPassword()
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
        }
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

        NavigationLink(isActive: $moveToRegister, destination: { RegisterStep1View() }, label: {})
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
        passwordOnChange: @escaping () -> Void
    )
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUIInputText(
                placeHolder: Localize.string("login_account_identity"),
                textFieldText: accountText,
                errorText: accountErrorText,
                textFieldType: GeneralType(
                    regex: .email,
                    keyboardType: .emailAddress
                )
            )

            SwiftUIInputText(
                placeHolder: Localize.string("common_password"),
                textFieldText: passwordText,
                errorText: passwordErrorText,
                featureType: .password,
                textFieldType: GeneralType(regex: .all)
            )

            HStack(spacing: 4) {
                if isRememberMe.wrappedValue {
                    Image("isRememberMe")
                } else {
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
        captchaTextOnChange: @escaping () -> Void
    )
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
                    textFieldType: GeneralType(regex: .numberAndEnglish)
                )
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
            }
        )
        .buttonStyle(.fill)
        .localized(weight: .regular, size: 16)
        .disabled(disabled)
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
            }
        )
        .localized(weight: .regular, size: 16)
    }
}

private extension LoginView {
    @ViewBuilder
    func resetPassword() -> some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/, spacing: 0) {
            Text(Localize.string("login_tips_1"))
                .foregroundColor(.from(.textPrimary))
            Text(" ")
            NavigationLink {
                ResetPasswordStep1View()
            } label: {
                Text(Localize.string("login_tips_1_highlight"))
                    .foregroundColor(.from(.primaryDefault))
            }
        }
        .localized(weight: .regular, size: 14)
    }
}

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}
