import sharedbu
import SwiftUI

struct WithdrawalOTPVerificationView<ViewModel>: View
    where ViewModel:
    WithdrawalOTPVerificationViewModelProtocol &
    ObservableObject
{
    @StateObject private var viewModel: ViewModel

    private let accountType: sharedbu.AccountType?

    private let otpVerifyOnCompleted: (() -> Void)?
    private let otpResentOnCompleted: (() -> Void)?
  
    private let onErrorRedirect: ((Error) -> Void)?

    init(
        viewModel: ViewModel,
        accountType: sharedbu.AccountType?,
        otpVerifyOnCompleted: (() -> Void)? = nil,
        otpResentOnCompleted: (() -> Void)? = nil,
        onErrorRedirect: ((Error) -> Void)? = nil)
    {
        self._viewModel = .init(wrappedValue: viewModel)

        self.accountType = accountType

        self.otpVerifyOnCompleted = otpVerifyOnCompleted
        self.otpResentOnCompleted = otpResentOnCompleted
    
        self.onErrorRedirect = onErrorRedirect
    }

    var body: some View {
        PageContainer(backgroundColor: .greyScaleDefault) {
            VStack(spacing: 40) {
                VerificationForm(
                    $viewModel.otpCode,
                    accountType)

                VerifyButtonAndResentHint(
                    viewModel.otpCode,
                    accountType,
                    otpVerifyOnCompleted,
                    otpResentOnCompleted,
                    onErrorRedirect)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 30)
        }
        .onPageLoading(viewModel.isLoading)
        .environmentObject(viewModel)
        .onAppear {
            guard let accountType else { return }

            viewModel.setup(accountType: accountType)
        }
    }
}

extension WithdrawalOTPVerificationView {
    // MARK: - VerificationForm

    struct VerificationForm: View {
        @EnvironmentObject private var viewModel: ViewModel

        @Binding private var otpCode: String

        private let accountType: sharedbu.AccountType?

        var inspection = Inspection<Self>()

        init(
            _ otpCode: Binding<String>,
            _ accountType: sharedbu.AccountType?)
        {
            self._otpCode = otpCode
            self.accountType = accountType
        }

        var body: some View {
            VStack(spacing: 30) {
                Text(viewModel.headerTitle)
                    .localized(weight: .semibold, size: 24, color: .greyScaleWhite)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack {
                    if let accountType {
                        switch accountType {
                        case .phone:
                            HighLightText(viewModel.sentCodeMessage)
                                .highLight(Localize.string("common_otp_hint_highlight"), with: .primaryDefault)
                                .id(HighLightText.Identifier)
                        case .email:
                            Text(viewModel.sentCodeMessage)
                        }
                    }
                }
                .localized(weight: .medium, size: 14, color: .textPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    VerifiedAlert(key: "register_step3_incorrect_otp")
                        .visibility(
                            viewModel.isVerifiedFail
                                ? .visible
                                : .gone)

                    OTPVerifyTextField($otpCode, length: viewModel.otpCodeLength)
                }
            }
            .onInspected(inspection, self)
        }
    }

    // MARK: - VerifyButtonAndResentHint

    struct VerifyButtonAndResentHint: View {
        @EnvironmentObject private var viewModel: ViewModel

        private let otpCode: String

        private let accountType: sharedbu.AccountType?

        private let otpVerifyOnCompleted: (() -> Void)?
        private let otpResentOnCompleted: (() -> Void)?
    
        private let onErrorRedirect: ((Error) -> Void)?

        init(
            _ otpCode: String,
            _ accountType: sharedbu.AccountType?,
            _ otpVerifyOnCompleted: (() -> Void)?,
            _ otpResentOnCompleted: (() -> Void)?,
            _ onErrorRedirect: ((Error) -> Void)?)
        {
            self.otpCode = otpCode
            self.accountType = accountType

            self.otpVerifyOnCompleted = otpVerifyOnCompleted
            self.otpResentOnCompleted = otpResentOnCompleted
      
            self.onErrorRedirect = onErrorRedirect
        }

        var body: some View {
            VStack(spacing: 24) {
                PrimaryButton(
                    title: Localize.string("common_verify"),
                    action: {
                        viewModel.verifyOTP(
                            onCompleted: otpVerifyOnCompleted,
                            onErrorRedirect: onErrorRedirect)
                    })
                    .disabled(
                        otpCode.count < viewModel.otpCodeLength ||
                            viewModel.isOTPVerifyInProgress)

                VStack(spacing: 0) {
                    HighLightText(
                        Localize.string("common_otp_resend_tips", viewModel.timerText) +
                            " " +
                            Localize.string("common_resendotp"))
                        // One more highLight to prevent transparent when have alpha.
                        .highLight(
                            Localize.string("common_resendotp"),
                            with: .greyScaleDefault)
                        .highLight(
                            Localize.string("common_resendotp"),
                            with: viewModel.isResentOTPEnable
                                ? .primaryDefault
                                : UIColor(.from(.primaryDefault, alpha: 0.5)))
                        .onTapGesture {
                            viewModel.resendOTP(
                                onCompleted: otpResentOnCompleted,
                                onErrorRedirect: onErrorRedirect)
                        }
                        .disabled(!viewModel.isResentOTPEnable)

                    Text(key: "common_email_spam_check")
                        .visibility(
                            accountType == .email
                                ? .visible
                                : .gone)
                }
                .localized(weight: .regular, size: 14, color: .textPrimary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Preview

struct WithdrawalOTPVerificationView_Previews: PreviewProvider {
    class FakeViewModel:
        WithdrawalOTPVerificationViewModelProtocol, ObservableObject
    {
        @Published private(set) var headerTitle = "验证电子邮箱"
        @Published private(set) var sentCodeMessage = "6位数字的验证码已经发送至\nstanleyho@gmail.com"

        @Published private(set) var otpCodeLength = 6
        @Published private(set) var timerText = "00:59"

        @Published private(set) var isLoading = false

        @Published private(set) var isResentOTPEnable = false
        @Published private(set) var isOTPVerifyInProgress = false

        @Published private(set) var isVerifiedFail = false

        @Published var otpCode = ""

        func setup(accountType _: sharedbu.AccountType) { }

        func verifyOTP(onCompleted _: (() -> Void)?, onErrorRedirect _: ((Error) -> Void)?) { }
    
        func resendOTP(onCompleted _: (() -> Void)?, onErrorRedirect _: ((Error) -> Void)?) { }
    }

    static var previews: some View {
        WithdrawalOTPVerificationView(
            viewModel: FakeViewModel(),
            accountType: .email)
    }
}
