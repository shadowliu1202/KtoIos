import NavigationBackport
import sharedbu
import SwiftUI

struct LoginView: View {
    enum NavType: Hashable {
        case resetPassword, register
    }

    @EnvironmentObject var navigator: PathNavigator
    @Environment(\.startManuelUpdate) private var startManuelUpdate
    @Environment(\.showDialog) var showDialog
    @StateObject var viewModel: LoginViewModel
    @State private var isLoadedData = false
    let isForceChinese: Bool
    let onLogin: (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void
    let onOtpLogin: () -> Void
    let toggleForceChinese: () -> Void

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
        .custom(NavigationItem<AnyView>("update_title", action: { startManuelUpdate() }))
    }

    private func register() -> ItemViews {
        .custom(NavigationItem<AnyView>(
            "common_register",
            action: {
                switch onEnum(of: viewModel.getSupportLocale()) {
                case .china:
                    #if QAT
                        navigator.push(NavType.register)
                    #else
                        showDialog(info: .init(
                            title: Localize.string("common_tip_cn_down_title_warm"),
                            message: Localize.string("common_cn_service_down"),
                            confirm: { navigator.push(NavType.register) },
                            confirmText: Localize.string("common_cn_down_confirm")
                        ))
                    #endif
                case .vietnam:
                    navigator.push(NavType.register)
                }
            }
        ))
    }

    var body: some View {
        LandingViewScaffold(navItem: .empty(), items: [manuelUpdate(), .cs(), register()]) {
            ZStack(alignment: .topLeading) {
                #if qat
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
                        if let key = viewModel.loginErrorKey {
                            loginError(.init(key))
                        }
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
                        resetPassword { navigator.push(NavType.resetPassword) }
                        LimitSpacer(30)
                        HStack {
                            Separator()
                            Text("common_or")
                                .font(size: 14)
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
        .onAppear { viewModel.refreshUI() }
        .nbNavigationDestination(for: NavType.self, destination: { dest in
            switch dest {
            case .register:
                RegisterStep1View()
            case .resetPassword:
                ResetPasswordStep1View()
            }
        })
    }

    @ViewBuilder
    private func loginTitle() -> some View {
        Text("common_login")
            .font(weight: .semibold, size: 24)
    }

    @ViewBuilder
    private func loginError(_ key: LocalizedStringKey) -> some View {
        Group {
            VerifiedAlert(key: key)
            LimitSpacer(12)
        }
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

                Text("login_account_remember_me")
                    .font(size: 12)
            }
            .onTapGesture { isRememberMe.wrappedValue.toggle() }
        }
        .onChange(of: accountText.wrappedValue) { _ in accountOnChange() }
        .onChange(of: passwordText.wrappedValue) { _ in passwordOnChange() }
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
                Text("login_captcha_new")
                    .font(weight: .medium, size: 14)
                    .foregroundStyle(.primaryDefault)
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
                    Text("common_login")
                    Text("(\(countDownSecond ?? 0))")
                        .visibility(countDownSecond == nil ? .gone : .visible)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
        )
        .buttonStyle(.fill)
        .disabled(disabled)
    }

    @ViewBuilder
    private func otpLoginButton(onPressed: @escaping () -> Void) -> some View {
        Button(
            action: { onPressed() },
            label: {
                Text("login_by_otp")
                    .foregroundColor(.from(.primaryDefault))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(Color.from(.textPrimary), lineWidth: 0.5)
                    )
            }
        )
    }
}

private extension LoginView {
    @ViewBuilder
    func resetPassword(onResetPassword: @escaping () -> Void) -> some View {
        VStack(content: {
            (
                Text("login_tips_1")
                    + Text(" ")
                    + Text("login_tips_1_highlight_link")
            )
            .tint(.primaryDefault)
            .environment(\.openURL, OpenURLAction { _ in
                onResetPassword()
                return .handled
            })
            .font(size: 14)
        })
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
