import Combine
import Foundation
import RxSwift
import sharedbu
import SwiftUI

struct ResetPasswordStep2View: View {
    @StateObject private var otpVerification: OtpVerification
    @State var moveToErroPage: Bool = false
    @State var moveToNext: Bool = false
    @State var errorKey: LocalizedStringKey? = nil
    @Environment(\.showDialog) var showDialog
    @Environment(\.handleError) var handleError
    @Environment(\.toastMessage) var toastMessage
    let selectMethod: AccountType
    let selectAccount: String

    init(selectMethod: AccountType, selectAccount: String) {
        self.selectMethod = selectMethod
        self.selectAccount = selectAccount
        _otpVerification = .init(wrappedValue: .init(accountType: selectMethod))
    }

    var body: some View {
        ContentView(
            selectMethod: selectMethod,
            accountIdentity: selectAccount,
            state: otpVerification.state,
            errorKey: errorKey,
            otpCode: $otpVerification.otpCode,
            onClickVerified: { otp in otpVerification.verifyResetOtp(otpCode: otp) },
            onClickResend: { otpVerification.resendOtp() }
        )
        .onConsume(handleError, otpVerification) { event in
            switch event {
            case .verified:
                moveToNext = true
            case let .exceedResendLimit(accountType):
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_tip_title_warm"),
                        message: accountType == .phone ? Localize.string("common_sms_otp_exeed_send_limit") : Localize
                            .string("common_email_otp_exeed_send_limit"),
                        confirm: { moveToErroPage = true }
                    )
                )
            case .fatalError:
                moveToErroPage = true
            case .resendSuccess:
                toastMessage(Localize.string("common_otp_send_success"), .success)
            case .wrongOtp:
                errorKey = "register_step3_incorrect_otp"
            }
        }
        .onChange(of: otpVerification.otpCode) { _ in errorKey = nil }

        NavigationLink(
            destination: ErrorPage(title: "login_resetpassword_fail_title"),
            isActive: $moveToErroPage,
            label: {}
        )
        NavigationLink(
            destination: ResetPasswordStep3View(),
            isActive: $moveToNext,
            label: {}
        )
    }
}

private struct ContentView: View {
    @Environment(\.showDialog) var showDialog
    @Environment(\.popToRoot) var popToRoot
    let selectMethod: AccountType
    let accountIdentity: String
    let state: OtpVerification.State
    let errorKey: LocalizedStringKey?
    @Binding var otpCode: String
    let onClickVerified: (String) -> Void
    let onClickResend: () -> Void
    var body: some View {
        LandingViewScaffold(
            navItem: .close {
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_confirm_cancel_operation"),
                        message: Localize.string("login_resetpassword_cancel_content"),
                        confirm: {
                            popToRoot()
                        },
                        cancel: {}
                    )
                )
            },
            items: [.cs()]
        ) {
            PageContainer(scrollable: true) {
                Group {
                    Text("login_resetpassword_step2_title_1")
                    Text(selectMethod == .phone ? "login_resetpassword_step2_verify_by_phone_title" :
                        "login_resetpassword_step2_verify_by_email_title")
                        .font(weight: .semibold, size: 24)

                    Spacer(minLength: 12)

                    Text(selectMethod == .phone ?"common_otp_hint_mobile" : "common_otp_hint_email")
                    Text(accountIdentity)
                }
                .font(weight: .medium, size: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 30)

                if let key = errorKey {
                    errorMessage(key)
                }
                OTPVerifyTextField($otpCode, length: state.otpLength)

                Spacer(minLength: 40)

                PrimaryButton(
                    key: "common_verify",
                    action: {
                        onClickVerified(otpCode)
                    }
                )
                .disabled(!state.isOtpValid)

                Spacer(minLength: 24)

                ResendHint(accountType: selectMethod, onResend: onClickResend)
            }
            .padding(.horizontal, 30)
        }
    }

    @ViewBuilder
    private func errorMessage(_ key: LocalizedStringKey) -> some View {
        Group {
            VerifiedAlert(key: key)
            LimitSpacer(12)
        }
    }
}

private struct ResendHint: View {
    let accountType: AccountType
    let onResend: () -> Void
    @State var countDown = Int(Setting.resendOtpCountDownSecond)
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(resendAttributedString())
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .font(weight: .regular, size: 14)
            .environment(\.openURL, .init(handler: { _ in
                countDown = Int(Setting.resendOtpCountDownSecond)
                startTimer()
                onResend()
                return .handled
            }))
            .onReceive(timer) { _ in
                if countDown > 0 {
                    countDown -= 1
                } else {
                    countDown = 0
                    stopTimer()
                }
            }

        if accountType == .email {
            Text("common_email_spam_check")
                .font(size: 14)
                .frame(maxWidth: .infinity)
        }
    }

    private func resendAttributedString() -> AttributedString {
        let base = AttributedString(localized: "common_otp_resend_tips \(countDown.toHourMinutesFormat())")
        var highlight = AttributedString(localized: "common_resendotp")
        var container = AttributeContainer()
        if countDown <= 0 {
            container.link = URL(string: "resend")
        }
        container.foregroundColor = countDown == 0 ? .primaryDefault : UIColor(.from(.primaryDefault, alpha: 0.5))
        highlight.setAttributes(container)
        return base + " " + highlight
    }

    func stopTimer() {
        timer.upstream.connect().cancel()
    }

    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}

struct ResetPasswordStep2View_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            selectMethod: .email,
            accountIdentity: "test@test.com",
            state: .init(),
            errorKey: nil,
            otpCode: .constant(""),
            onClickVerified: { _ in },
            onClickResend: {}
        )
    }
}
