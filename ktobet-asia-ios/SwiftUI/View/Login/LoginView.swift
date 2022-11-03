import SwiftUI
import SharedBu

struct LoginView: View {
    @StateObject var viewModel: NewLoginViewModel = Injectable.resolve(NewLoginViewModel.self)!
    
    @State private var isLoadedData: Bool = false
    
    var onLogin = { (pageNavigation: NavigationViewModel.LobbyPageNavigation?, generalError: Error?) -> Void in }
    var onResetPassword = { () -> Void in }
    
    private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    self.loginTitle()
                    LimitSpacer(30)
                    self.loginError(viewModel.getLoginErrorText())
                    self.loginInputTextField($viewModel.account,
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
                    self.captcha($viewModel.captchaText,
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
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30 )
            }
        }
        .pageBackgroundColor(.defaultGray)
        .playerLocale(localStorageRepo.getSupportLocale())
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
            .customizedFont(fontWeight: .semibold, size: 24, color: .primaryGray)
    }
    
    @ViewBuilder
    private func loginError(_ text: String?) -> some View {
        Group {
            Text(text ?? "")
                .alertStyle()
            LimitSpacer(12)
        }
        .visibility(text == nil ? .gone : .visible)
    }
    
    @ViewBuilder
    private func loginInputTextField(_ accountText: Binding<String>,
                                     _ accountErrorText: String?,
                                     _ passwordText: Binding<String>,
                                     _ passwordErrorText: String?,
                                     _ isRememberMe: Binding<Bool>, accountOnChange: @escaping () -> Void, passwordOnChange: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SwiftUIInputText(placeHolder: Localize.string("login_account_identity"),
                             textFieldText: accountText,
                             errorText: accountErrorText)
            SwiftUIInputText(placeHolder: Localize.string("common_password"),
                             textFieldText: passwordText,
                             errorText: passwordErrorText,
                             isPasswordType: true)
            HStack(spacing: 4) {
                if isRememberMe.wrappedValue {
                    Image("isRememberMe")
                } else {
                    Circle()
                        .strokeBorder(Color.primaryGray, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .padding(1)
                }
                
                Text(Localize.string("login_account_remember_me"))
                    .customizedFont(fontWeight: .regular, size: 12, color: .primaryGray)
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
    private func captcha(_ text: Binding<String>, _ errorText: String?, _ image: UIImage?, getCaptchaOnTap: @escaping () -> Void, captchaTextOnChange: @escaping () -> Void) -> some View {
        Group {
            LimitSpacer(30)
            VStack(spacing: 12) {
                Text(Localize.string("login_enter_captcha_to_prceed"))
                    .alertStyle()
                SwiftUIInputText(placeHolder: Localize.string("login_captcha"), textFieldText: text, errorText: errorText)
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 32)
                Text(Localize.string("login_captcha_new"))
                    .customizedFont(fontWeight: .medium, size: 14, color: .primaryRed)
                    .onTapGesture {
                        getCaptchaOnTap()
                    }
            }
        }
        .visibility(image == nil ? .gone : .visible )
        .onChange(of: text.wrappedValue) { _ in
            captchaTextOnChange()
        }
        .accessibilityIdentifier("captcha")
    }
    
    @ViewBuilder
    private func loginButton(_ countDownSecond: Int?, _ disabled: Bool , onPressed: @escaping () -> Void) -> some View {
        Button {
            onPressed()
        } label: {
            HStack(spacing: 0) {
                Text(Localize.string("common_login"))
                Text("(\(countDownSecond ?? 0))")
                    .visibility(countDownSecond == nil ? .gone : .visible)
            }
        }
        .buttonStyle(.confirmRed)
        .disabled(disabled)
    }
    
    @ViewBuilder
    private func resetPassword(onTapped: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(Localize.string("login_tips_1"))
                .foregroundColor(.primaryGray)
            Text(" ")
            Text(Localize.string("login_tips_1_highlight"))
                .foregroundColor(.primaryRed)
                .onTapGesture {
                    onTapped()
                }
        }
        .customizedFont(fontWeight: .regular, size: 14, color: nil)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLogin: {_, _ in }, onResetPassword: {})
    }
}
