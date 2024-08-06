import Combine
import Foundation
import RxSwift
import sharedbu
import SwiftUI

struct RegisterStep3MobileView: View {
    @StateObject private var viewModel: RegisterStep3Mobile
    @State var moveToErrorPage: Bool = false
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
            }
        }
        NavigationLink(
            destination: ErrorPage(
                title: "register_step4_title_fail",
                message: "register_step4_content_fail",
                button: Localize.string("register_step4_retry_signup")
            ),
            isActive: $moveToErrorPage,
            label: {}
        )
    }
}

private struct ContentView: View {
    @Environment(\.showDialog) var showDialog
    @Environment(\.popToRoot) var popToRoot
    let identity: String
    let state: RegisterStep3Mobile.State
    @Binding var otpCode: String
    let onClickVerified: (String) -> Void
    let onClickResend: () -> Void
    var body: some View {
        LandingViewScaffold(
            navItem: .close {
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_tip_title_unfinished"),
                        message: Localize.string("common_tip_content_unfinished"),
                        confirm: { popToRoot() },
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
                        .localized(weight: .semibold, size: 24, color: .textPrimary)

                    Spacer(minLength: 12)

                    Text("common_otp_sent_content_mobile")
                    Text(identity)
                }
                .localized(weight: .medium, size: 14, color: .textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 30)

                errorMessage(state.errorMessage)
                OTPVerifyTextField($otpCode, length: state.otpLength)

                Spacer(minLength: 40)

                PrimaryButton(
                    title: Localize.string("common_verify"),
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
    private func errorMessage(_ text: String?) -> some View {
        Group {
            VerifiedAlert(text ?? "")
            LimitSpacer(12)
        }
        .visibility(text == nil ? .gone : .visible)
    }
}

private struct ResendHint: View {
    let accountType: AccountType
    let onResend: () -> Void
    @State var countDown = Int(Setting.resendOtpCountDownSecond)
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HighLightText(
            Localize.string("common_otp_resend_tips", countDown.toHourMinutesFormat()) + " " + Localize.string("common_resendotp")
        )
        .highLight(
            Localize.string("common_resendotp"),
            with: countDown == 0 ? .primaryDefault : UIColor(.from(.primaryDefault, alpha: 0.5))
        )
        .onTapGesture {
            countDown = Int(Setting.resendOtpCountDownSecond)
            startTimer()
            onResend()
        }
        .disabled(countDown > 0)
        .localized(weight: .regular, size: 14, color: .textPrimary)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
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
                .localized(weight: .regular, size: 14, color: .textPrimary)
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
            onClickVerified: { _ in },
            onClickResend: {}
        )
    }
}
