import Combine
import Foundation
import NavigationBackport
import RxSwift
import sharedbu
import SwiftUI

struct RegisterStep3MobileView: View {
    @StateObject private var viewModel: RegisterStep3Mobile
    @State var moveToErrorPage: Bool = false
    @State var errorMessageKey: LocalizedStringKey? = nil
    @Environment(\.showDialog) var showDialog
    @Environment(\.handleError) var handleError
    @Environment(\.toastMessage) var toastMessage
    @Environment(\.enterLobby) var enterLobby
    let identity: String

    init(identity: String) {
        self.identity = identity
        _viewModel = .init(wrappedValue: .init())
    }

    var body: some View {
        ContentView(
            identity: identity,
            state: viewModel.state,
            otpCode: $viewModel.otpCode,
            errorKey: errorMessageKey,
            onClickVerified: { otp in viewModel.verifyOtp(otpCode: otp) },
            onClickResend: { viewModel.resendOtp() }
        )
        .onConsume(handleError, viewModel) { event in
            switch event {
            case let .verified(productType):
                enterLobby(productType: productType)
            case .exceedResendLimit:
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_tip_title_warm"),
                        message: Localize.string("common_sms_otp_exeed_send_limit"),
                        confirm: { moveToErrorPage = true }
                    )
                )
            case .fatalError:
                moveToErrorPage = true
            case .resendSuccess:
                toastMessage(Localize.string("common_otp_send_success"), .success)
            case .wrongOtp:
                errorMessageKey = "register_step3_incorrect_otp"
            }
        }
        .nbNavigationDestination(isPresented: $moveToErrorPage) {
            ErrorPage(
                title: "register_step4_title_fail",
                message: "register_step4_content_fail",
                button: "register_step4_retry_signup"
            )
        }
    }
}

private struct ContentView: View {
    @Environment(\.showDialog) var showDialog
    @EnvironmentObject var navigator: PathNavigator
    let identity: String
    let state: RegisterStep3Mobile.State
    @Binding var otpCode: String
    let errorKey: LocalizedStringKey?
    let onClickVerified: (String) -> Void
    let onClickResend: () -> Void
    var body: some View {
        LandingViewScaffold(
            navItem: .close {
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_tip_title_unfinished"),
                        message: Localize.string("common_tip_content_unfinished"),
                        confirm: { navigator.popToRoot() },
                        cancel: {}
                    )
                )
            },
            items: [.cs()]
        ) {
            PageContainer(scrollable: true) {
                Group {
                    Text("register_step3_title_1")
                    Text("register_step3_verify_by_phone_title")
                        .font(weight: .semibold, size: 24)

                    Spacer(minLength: 12)

                    Text("common_otp_sent_content_mobile")
                    Text(identity)
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
                    action: { onClickVerified(otpCode) }
                )
                .disabled(!state.isOtpValid || state.isProcessing)

                Spacer(minLength: 24)

                ResendHint(accountType: .phone, onResend: onClickResend)
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
        (
            Text("common_otp_resend_tips \(countDown.toHourMinutesFormat())")
                + Text(" ")
                + Text("common_resendotp_link")
        )
        .tint(countDown == 0 ? .primaryDefault : Color(uiColor: .primaryDefault.withAlphaComponent(0.5)))
        .font(weight: .regular, size: 14)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .environment(\.openURL, OpenURLAction { _ in
            if countDown == 0 {
                countDown = Int(Setting.resendOtpCountDownSecond)
                startTimer()
                onResend()
            }
            return .handled
        })
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

    func stopTimer() {
        timer.upstream.connect().cancel()
    }

    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}

struct RegisterStep3MobileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            identity: "0123456789",
            state: .init(),
            otpCode: .constant(""),
            errorKey: nil,
            onClickVerified: { _ in },
            onClickResend: {}
        )
    }
}
