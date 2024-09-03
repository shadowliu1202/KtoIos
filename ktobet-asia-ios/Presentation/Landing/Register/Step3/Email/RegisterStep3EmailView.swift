import Foundation
import NavigationBackport
import SwiftUI

struct RegisterStep3EmailView: View {
    let identity: String
    let password: String

    @StateObject private var viewModel: RegisterStep3Email
    @Environment(\.handleError) var handleError
    @Environment(\.showDialog) var showDialog
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigator: PathNavigator
    @Environment(\.toastMessage) var toastMessage
    @Environment(\.enterLobby) var enterLobby

    init(identity: String, password: String) {
        self.identity = identity
        self.password = password
        _viewModel = .init(wrappedValue: .init(identity, password))
    }

    var body: some View {
        ContentView(
            isAutoVerify: $viewModel.isAutoVerify,
            identity: identity,
            onResend: { viewModel.resend() },
            onVerify: { viewModel.manualVerify(identity, password) }
        )
        .onConsume(handleError, viewModel) { event in
            switch event {
            case let .verified(productType):
                enterLobby(productType: productType)
            case .invalid:
                showDialog(info: .init(
                    title: Localize.string("common_tip_title_warm"),
                    message: Localize.string("register_step3_verification_pending")
                ))
            case .resendSuccess:
                toastMessage(Localize.string("common_otp_send_success"), .success)
            case .exceedLimit:
                showDialog(
                    info: .init(
                        title: Localize.string("common_tip_title_warm"),
                        message: Localize.string("common_email_otp_exeed_send_limit"),
                        confirm: { navigator.popToRoot() }
                    )
                )
            }
        }
    }
}

private struct ContentView: View {
    @Environment(\.showDialog) var showDialog
    @EnvironmentObject var navigator: PathNavigator
    @Binding var isAutoVerify: Bool

    let identity: String
    let onResend: () -> Void
    let onVerify: () -> Void

    var body: some View {
        LandingViewScaffold(
            navItem: .close {
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_confirm_cancel_operation"),
                        message: Localize.string("login_resetpassword_cancel_content"),
                        confirm: { navigator.popToRoot() },
                        cancel: {}
                    )
                )
            },
            items: [.cs()]
        ) {
            PageContainer(scrollable: true) {
                VStack(spacing: 0) {
                    #if qat
                        Toggle("(QAT) Auto verify", isOn: $isAutoVerify)
                    #endif
                    Text("register_step3_title_1")
                        .font(weight: .medium, size: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("register_step3_verify_by_email_title")
                        .font(weight: .semibold, size: 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LimitSpacer(12)
                    Text("register_step3_content_email \(identity)")
                        .font(weight: .medium, size: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    LimitSpacer(40)

                    Button {
                        if let mailUrl = URL(string: "message://"), UIApplication.shared.canOpenURL(mailUrl) {
                            UIApplication.shared.open(mailUrl, options: [:], completionHandler: nil)
                        }
                    } label: {
                        Text("register_step3_open_mail")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.fill)

                    LimitSpacer(24)
                    ResendHint(accountType: .email, onResend: {})

                    LimitSpacer(24)

                    (
                        Text("register_step3_mail_varify_hint")
                            + Text(" ")
                            + Text("register_step3_mail_varify_hint_highlight_link")
                    )
                    .tint(.primaryDefault)
                    .environment(\.openURL, .init(handler: { _ in
                        onVerify()
                        return .handled
                    }))
                    .font(weight: .regular, size: 14)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
            }
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

struct RegisterStep3EmailView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView(
            isAutoVerify: .constant(true),
            identity: "abc@def.ghi",
            onResend: {},
            onVerify: {}
        )
    }
}
