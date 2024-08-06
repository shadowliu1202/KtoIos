import Foundation
import sharedbu
import SwiftUI

struct ResetPasswordStep1View: View {
    @StateObject private var viewModel = ResetPasswordStep1Object()
    @Environment(\.handleError) var handleError
    @Environment(\.showDialog) var showDialog
    @Environment(\.dismiss) var dismiss
    @Environment(\.toastMessage) var toastMessage

    private struct MoveToNext: Equatable {
        var isActive: Bool = false
        var type: AccountType = .email
        var identity: String = ""
    }

    @State private var moveToNext: MoveToNext = .init()

    var body: some View {
        ContentView(
            state: viewModel.state,
            selectedMethod: $viewModel.accountType,
            otpStatus: viewModel.otpStatus,
            onInputChange: viewModel.clearErrorMessage,
            requestResetPassword: viewModel.requestPasswordReset
        )
        .onAppear { viewModel.refreshOtpStatus() }
        .disabled(viewModel.state.isProcessing)
        .onConsume(handleError, viewModel) { event in
            switch event {
            case let .exceedResendLimit(selectMethod):
                let message = selectMethod == .phone
                    ? Localize.string("common_sms_otp_exeed_send_limit")
                    : Localize.string("common_email_otp_exeed_send_limit")
                showDialog(info: ShowDialog.Info(
                    title: Localize.string("common_tip_title_warm"),
                    message: message,
                    confirm: { dismiss() },
                    tintColor: UIColor.primaryDefault
                ))
            case let .moveToNextStep(type, identity):
                toastMessage(Localize.string("common_otp_send_success"), .success)
                moveToNext = .init(isActive: true, type: type, identity: identity)
            }
        }

        NavigationLink(isActive: $moveToNext.isActive) {
            ResetPasswordStep2View(
                selectMethod: moveToNext.type,
                selectAccount: moveToNext.identity
            )
        } label: {}
    }
}

private struct ContentView: View {
    let state: ResetPasswordStep1Object.State
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var countDownSecond: Int? = nil
    @Binding var selectedMethod: AccountType
    let otpStatus: OtpStatus

    let onInputChange: (AccountType) -> Void
    let requestResetPassword: (AccountType, String) -> Void

    var body: some View {
        LandingViewScaffold(items: [.cs()]) {
            PageContainer(scrollable: false, bottomPadding: 0) {
                VStack(spacing: 0) {
                    Text("login_resetpassword_step1_title_1")
                        .font(weight: .medium, size: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("login_resetpassword_step1_title_2")
                        .font(weight: .semibold, size: 24)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LimitSpacer(30)
                    AccountTypePicker(selection: $selectedMethod)
                    LimitSpacer(12)
                }
                .padding(.horizontal, 30)

                TabView(selection: $selectedMethod) {
                    ForEach(AccountType.allCases) { type in
                        switch type {
                        case .phone:
                            phoneForm()
                        case .email:
                            emailForm()
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .onReceive(timer) { _ in
                guard let countDown = state.remainLockSecond else {
                    countDownSecond = nil
                    return stopTimer()
                }
                countDownSecond = countDown
            }
            .onChange(of: state.lockUntil) { lockTime in
                if lockTime != nil {
                    countDownSecond = state.remainLockSecond
                    startTimer()
                }
            }
        }
    }

    @ViewBuilder
    private func phoneForm() -> some View {
        if otpStatus.isSmsActive {
            ResetInfoForm(
                locale: state.locale,
                accountType: .phone,
                errorMsg: state.mobileErrorMessage,
                lockSeconds: countDownSecond ?? state.remainLockSecond,
                onInputChange: onInputChange,
                submit: requestResetPassword
            )
        } else {
            maintenanceView("login_resetpassword_step1_sms_inactive")
        }
    }

    @ViewBuilder
    private func emailForm() -> some View {
        if otpStatus.isMailActive {
            ResetInfoForm(
                locale: state.locale,
                accountType: .email,
                errorMsg: state.emailErrorMessage,
                lockSeconds: countDownSecond ?? state.remainLockSecond,
                onInputChange: onInputChange,
                submit: requestResetPassword
            )
        } else {
            maintenanceView("login_resetpassword_step1_email_inactive")
        }
    }

    func stopTimer() {
        timer.upstream.connect().cancel()
    }

    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}

private struct ResetInfoForm: View {
    init(
        locale: SupportLocale,
        accountType: AccountType,
        errorMsg: String?,
        lockSeconds: Int?,
        onInputChange: @escaping (AccountType) -> Void,
        submit: @escaping (AccountType, String) -> Void
    ) {
        _account = .init(wrappedValue: .init(locale: locale, accountType: accountType))
        self.errorMsg = errorMsg
        self.onInputChange = onInputChange
        self.submit = submit
        self.lockSeconds = lockSeconds
    }

    @StateObject private var account: AccountVerification
    let lockSeconds: Int?
    let errorMsg: String?
    let onInputChange: (AccountType) -> Void
    let submit: (AccountType, String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                LimitSpacer(12)
                errorMessage(errorMsg)

                switch account.state.accountType {
                case .phone:
                    SwiftUIInputText(
                        placeHolder: Localize.string("common_mobile"),
                        textFieldText: $account.state.identity ?? account.state.areaCode,
                        errorText: account.state.verifyMobileError() ?? "",
                        textFieldType: GeneralType(regex: .all, keyboardType: .phonePad)
                    )
                case .email:
                    SwiftUIInputText(
                        placeHolder: Localize.string("common_email"),
                        textFieldText: $account.state.identity ?? "",
                        errorText: account.state.verifyEmailError() ?? "",
                        textFieldType: GeneralType(regex: .all, keyboardType: .emailAddress)
                    )
                }
                LimitSpacer(40)
                resetButton(lockSeconds, !account.state.isIdentityValid || lockSeconds != nil) {
                    submit(
                        account.state.accountType,
                        account.state.rawIdentity!
                    )
                }
                LimitSpacer(96)
            }
            .padding(.horizontal, 30)
            .onChange(of: account.state) { _ in onInputChange(account.state.accountType) }
        }
    }

    @ViewBuilder
    private func errorMessage(_ text: String?) -> some View {
        Group {
            VerifiedAlert(text ?? "")
            LimitSpacer(12)
        }
        .visibility(text == nil ? .gone : .visible)
    }

    @ViewBuilder
    private func resetButton(_ countDownSecond: Int?, _ disabled: Bool, onPressed: @escaping () -> Void) -> some View {
        Button(
            action: onPressed,
            label: {
                HStack(spacing: 0) {
                    Text("common_get_code")
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
}

private extension ContentView {
    @ViewBuilder
    private func maintenanceView(_ key: LocalizedStringKey) -> some View {
        VStack(spacing: 0) {
            LimitSpacer(40)
            Image(uiImage: UIImage(named: "Maintenance"))
            Text(key)
                .font(weight: .regular, size: 14)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 30)
    }

    @ViewBuilder
    private func errorMessage(_ text: String?) -> some View {
        Group {
            VerifiedAlert(text ?? "")
            LimitSpacer(12)
        }
        .visibility(text == nil ? .gone : .visible)
    }
}

private extension AccountVerification.AccountState {
    func verifyEmailError() -> String? {
        switch isEmailValid() {
        case .empty:
            Localize.string("common_field_must_fill")
        case .invalidFormat:
            Localize.string("common_error_email_format")
        case .valid: ""
        case .none: nil
        }
    }

    func verifyMobileError() -> String? {
        switch isMobileValid() {
        case .empty:
            Localize.string("common_field_must_fill")
        case .invalidFormat:
            Localize.string("common_error_mobile_format")
        case .valid: ""
        case .none: nil
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            state: .init(),
            selectedMethod: .constant(.phone),
            otpStatus: .init(isMailActive: true, isSmsActive: true),
            onInputChange: { _ in },
            requestResetPassword: { _, _ in }
        )
    }
}

struct ResetPasswordViewInactive_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            state: .init(),
            selectedMethod: .constant(.phone),
            otpStatus: .init(isMailActive: false, isSmsActive: false),
            onInputChange: { _ in },
            requestResetPassword: { _, _ in }
        )
    }
}
