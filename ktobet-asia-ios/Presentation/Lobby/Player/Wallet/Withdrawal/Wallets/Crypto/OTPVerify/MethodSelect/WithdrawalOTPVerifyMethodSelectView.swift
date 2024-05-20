import sharedbu
import SwiftUI

struct WithdrawalOTPVerifyMethodSelectView<ViewModel>: View
    where ViewModel:
    WithdrawalOTPVerifyMethodSelectViewModelProtocol &
    ObservableObject
{
    @StateObject private var viewModel: ViewModel

    private let bankCardID: String?

    private let otpServiceUnavailable: (() -> Void)?
    private let otpRequestOnCompleted: ((_ selectedAccountType: sharedbu.AccountType) -> Void)?

    init(
        viewModel: ViewModel,
        bankCardID: String? = nil,
        otpServiceUnavailable: (() -> Void)? = nil,
        otpRequestOnCompleted: ((_ selectedAccountType: sharedbu.AccountType) -> Void)? = nil)
    {
        self._viewModel = .init(wrappedValue: viewModel)

        self.bankCardID = bankCardID

        self.otpServiceUnavailable = otpServiceUnavailable
        self.otpRequestOnCompleted = otpRequestOnCompleted
    }

    var body: some View {
        PageContainer(backgroundColor: .greyScaleDefault, bottomPadding: 0) {
            VStack(spacing: 0) {
                VStack(spacing: 30) {
                    Text(key: "common_select_verify_type")
                        .localized(weight: .semibold, size: 24, color: .greyScaleWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)

                    HStack(spacing: 0) {
                        Button(
                            action: {
                                viewModel.selectedAccountType = .phone
                            },
                            label: {
                                Text(key: "common_mobile")
                            })
                            .buttonStyle(.tabGray(onSelected: viewModel.selectedAccountType == .phone))

                        Button(
                            action: {
                                viewModel.selectedAccountType = .email
                            },
                            label: {
                                Text(key: "common_email")
                            })
                            .buttonStyle(.tabGray(onSelected: viewModel.selectedAccountType == .email))
                    }
                    .backgroundColor(.greyScaleDefault)
                    .padding(.horizontal, 30)
                }

                switch viewModel.otpServiceAvailability {
                case .available(let infoHint, let isRequestAvailable):
                    SelectMethodForm(
                        infoHint,
                        isRequestAvailable,
                        bankCardID ?? "",
                        otpRequestOnCompleted)

                case .unavailable(let hint):
                    SwiftUIEmptyStateView(
                        iconImage: Image("Maintenance"),
                        description: hint,
                        keyboardAppearance: .impossible)
                }
            }
        }
        .onPageLoading(viewModel.isLoading)
        .environmentObject(viewModel)
        .onAppear {
            viewModel.setup(otpServiceUnavailable)
        }
    }
}

extension WithdrawalOTPVerifyMethodSelectView {
    // MARK: - SelectMethodForm

    struct SelectMethodForm: View {
        @EnvironmentObject private var viewModel: ViewModel

        private let infoHint: String
        private let isRequestAvailable: Bool

        private let bankCardID: String

        private let otpRequestOnCompleted: ((_ selectedAccountType: sharedbu.AccountType) -> Void)?

        var inspection = Inspection<Self>()

        init(
            _ infoHint: String,
            _ isRequestAvailable: Bool,
            _ bankCardID: String,
            _ otpRequestOnCompleted: ((_ selectedAccountType: sharedbu.AccountType) -> Void)?)
        {
            self.infoHint = infoHint
            self.isRequestAvailable = isRequestAvailable
            self.bankCardID = bankCardID
            self.otpRequestOnCompleted = otpRequestOnCompleted
        }

        var body: some View {
            VStack(spacing: 40) {
                HighLightText(infoHint)
                    .highLight(Localize.string("common_otp_hint_highlight"), with: .primaryDefault)
                    .id(HighLightText.Identifier)
                    .localized(weight: .medium, size: 14, color: .textPrimary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                PrimaryButton(
                    title: Localize.string("common_get_code"),
                    action: {
                        viewModel.requestOTP(
                            bankCardID: bankCardID,
                            onCompleted: otpRequestOnCompleted)
                    })
                    .disabled(viewModel.isOTPRequestInProgress)
                    .visibility(isRequestAvailable ? .visible : .gone)
            }
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .frame(maxHeight: .infinity, alignment: .top)
            .onInspected(inspection, self)
        }
    }
}

// MARK: - Preview

struct WithdrawalOTPVerifyMethodSelectView_Previews: PreviewProvider {
    class FakeViewModel:
        WithdrawalOTPVerifyMethodSelectViewModelProtocol &
        ObservableObject
    {
        @Published var otpServiceAvailability: WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus
        @Published var isLoading = false
        @Published var isOTPRequestInProgress = false
        @Published var selectedAccountType: sharedbu.AccountType = .email

        init(otpServiceAvailability: WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus) {
            self.otpServiceAvailability = otpServiceAvailability
        }

        func setup(_: (() -> Void)?) { }

        func requestOTP(
            bankCardID _: String,
            onCompleted _: ((_ selectedAccountType: sharedbu.AccountType) -> Void)?) { }
    }

    static var previews: some View {
        WithdrawalOTPVerifyMethodSelectView(
            viewModel: FakeViewModel(
                otpServiceAvailability:
                .available("6位数字的验证码将发送至\nstanleyho@gmail.com", true)))
            .previewDisplayName("Available")

        WithdrawalOTPVerifyMethodSelectView(
            viewModel: FakeViewModel(
                otpServiceAvailability:
                .unavailable("非常抱歉，该注册方式暂不可用。")))
            .previewDisplayName("Service down")

        WithdrawalOTPVerifyMethodSelectView(
            viewModel: FakeViewModel(
                otpServiceAvailability:
                .available("尚未设定信箱", false)))
            .previewDisplayName("Contact not set")
    }
}
