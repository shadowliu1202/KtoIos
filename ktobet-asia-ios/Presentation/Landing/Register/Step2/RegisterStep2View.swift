import Combine
import sharedbu
import SwiftUI

struct RegisterStep2View: View {
    @StateObject private var viewModel = RegisterStep2()
    @Environment(\.handleError) var handleError
    @Environment(\.showDialog) var showDialog
    @Environment(\.dismiss) var dismiss
    @Environment(\.popToRoot) var popToRoot
    @Environment(\.toastMessage) var toastMessage

    @State private var moveToNext: MoveToNext = .init()
    @State private var mobileError: RegisterStep2.Warning? = nil
    @State private var emailError: RegisterStep2.Warning? = nil

    private struct MoveToNext {
        var accountType: AccountType? = nil
        var identity: String = ""
        var password: String = ""
    }

    var body: some View {
        Content(
            accountType: $viewModel.accountType,
            otpStatus: viewModel.otpStatus,
            state: viewModel.state,
            mobileErrorType: mobileError,
            emailErrorType: emailError,
            onInputChange: { accountType in
                switch accountType {
                case .phone:
                    mobileError = nil
                case .email:
                    emailError = nil
                }
            },
            requestRegister: viewModel.requestRegister
        )
        .onConsume(handleError, viewModel) { event in
            switch event {
            case .blocked:
                showDialog(
                    info: ShowDialog.Info(
                        title: Localize.string("common_tip_title_warm"),
                        message: Localize.string("register_step2_unusual_activity"),
                        confirm: { popToRoot() },
                        confirmText: Localize.string("common_determine")
                    )
                )

            case let .proceedRegistration(type, identity, password):
                toastMessage(
                    type == .phone ? Localize.string("common_otp_send_success") : Localize.string("common_otp_mail_send_success"),
                    .success
                )

                moveToNext = .init(accountType: type, identity: identity, password: password)

            case let .notifyErrorMessage(accountType, errorType):
                switch accountType {
                case .phone:
                    mobileError = errorType
                case .email:
                    emailError = errorType
                }
            }
        }
        .disabled(viewModel.state.isProcessing)

        NavigationLink(
            destination: RegisterStep3EmailView(identity: moveToNext.identity, password: moveToNext.password),
            tag: .email,
            selection: $moveToNext.accountType,
            label: {}
        )

        NavigationLink(
            destination: RegisterStep3MobileView(identity: moveToNext.identity),
            tag: .phone,
            selection: $moveToNext.accountType,
            label: {}
        )
    }
}

private struct Content: View {
    @Binding var accountType: AccountType
    let otpStatus: OtpStatus
    var state: RegisterStep2.State
    let mobileErrorType: RegisterStep2.Warning?
    let emailErrorType: RegisterStep2.Warning?
    let onInputChange: (AccountType) -> Void
    let requestRegister: (AccountType, String, String, String) -> Void

    var body: some View {
        LandingViewScaffold(items: [.cs()]) {
            PageContainer(scrollable: false, bottomPadding: 0) {
                VStack(spacing: 0) {
                    Text("register_step2_title_1")
                        .font(weight: .medium, size: 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("register_step2_title_2")
                        .font(weight: .semibold, size: 24)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LimitSpacer(30)
                    AccountTypePicker(selection: $accountType)
                    LimitSpacer(12)
                }
                .padding(.horizontal, 30)

                TabView(selection: $accountType) {
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
        }
    }

    @ViewBuilder
    private func phoneForm() -> some View {
        if otpStatus.isSmsActive {
            AccountInfoForm(
                locale: state.locale,
                accountType: .phone,
                errorMsg: mobileErrorType?.toMobileKey(),
                onInputChange: onInputChange,
                submit: requestRegister
            )
        } else {
            maintenanceView("register_step2_sms_inactive")
        }
    }

    @ViewBuilder
    private func emailForm() -> some View {
        if otpStatus.isMailActive {
            AccountInfoForm(
                locale: state.locale,
                accountType: .email,
                errorMsg: emailErrorType?.toEmailKey(),
                onInputChange: onInputChange,
                submit: requestRegister
            )
        } else {
            maintenanceView("register_step2_email_inactive")
        }
    }

    @ViewBuilder
    private func maintenanceView(_ key: LocalizedStringKey) -> some View {
        VStack(spacing: 0) {
            LimitSpacer(40)
            Image(uiImage: UIImage(named: "Maintenance"))
            Text(key)
                .font(size: 14)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 30)
    }

    private struct AccountInfoForm: View {
        init(
            locale: SupportLocale,
            accountType: AccountType,
            errorMsg: LocalizedStringKey?,
            onInputChange: @escaping (AccountType) -> Void,
            submit: @escaping (AccountType, String, String, String) -> Void
        ) {
            _account = .init(wrappedValue: .init(locale: locale, accountType: accountType))
            self.errorMsg = errorMsg
            self.onInputChange = onInputChange
            self.submit = submit
        }

        @StateObject private var account: RegisterStep2Account

        let errorMsg: LocalizedStringKey?
        let onInputChange: (AccountType) -> Void
        let submit: (AccountType, String, String, String) -> Void

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
                            errorText: account.state.mobileError(),
                            textFieldType: GeneralType(regex: .all, keyboardType: .phonePad)
                        )
                    case .email:
                        SwiftUIInputText(
                            placeHolder: Localize.string("common_email"),
                            textFieldText: $account.state.identity ?? "",
                            errorText: account.state.emailError(),
                            textFieldType: GeneralType(regex: .all, keyboardType: .emailAddress)
                        )
                    }
                    LimitSpacer(12)
                    SwiftUIInputText(
                        placeHolder: Localize.string("common_realname"),
                        textFieldText: $account.state.name ?? "",
                        errorText: account.state.nameError(),
                        textFieldType: GeneralType(regex: .all, keyboardType: .default)
                    )
                    LimitSpacer(12)
                    PasswordConfirmView(
                        password: $account.state.password ?? "",
                        passwordConfirm: $account.state.passwordConfirm ?? "",
                        errorMessage: account.state.passwordError()
                    )
                    LimitSpacer(12)
                    Text("common_password_tips_1")
                        .font(weight: .medium, size: 14)
                    LimitSpacer(40)
                    Button {
                        submit(
                            account.state.accountType,
                            account.state.nonPrefixIdentity!,
                            account.state.name!,
                            account.state.password!
                        )
                    } label: {
                        Text("common_next")
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.fill)
                    .disabled(!account.state.isSubmitValid)
                    LimitSpacer(96)
                }
                .padding(.horizontal, 30)
                .onChange(of: account.state) { _ in onInputChange(account.state.accountType) }
            }
        }

        @ViewBuilder
        private func errorMessage(_ key: LocalizedStringKey?) -> some View {
            if let key {
                Group {
                    VerifiedAlert(key: key)
                    LimitSpacer(12)
                }
            }
        }
    }
}

private extension RegisterStep2.Warning {
    func toMobileKey() -> LocalizedStringKey {
        switch self {
        case .overLimit:
            "common_sms_otp_exeed_send_limit"
        case .accountExist:
            "common_error_phone_verify"
        }
    }

    func toEmailKey() -> LocalizedStringKey {
        switch self {
        case .overLimit:
            "common_email_otp_exeed_send_limit"
        case .accountExist:
            "common_error_email_verify"
        }
    }
}

private extension RegisterStep2Account.AccountState {
    func passwordError() -> LocalizedStringKey? {
        switch passwordResult {
        case .empty:
            "common_field_must_fill"
        case .invalidFormat:
            "common_field_format_incorrect"
        case .notMatch:
            "register_step2_password_not_match"
        case .valid, .none:
            nil
        }
    }

    func emailError() -> String {
        switch identityResult {
        case .empty:
            Localize.string("common_field_must_fill")
        case .invalidFormat:
            Localize.string("common_error_email_format")
        case .valid, .none:
            ""
        }
    }

    func mobileError() -> String {
        switch identityResult {
        case .empty:
            Localize.string("common_field_must_fill")
        case .invalidFormat:
            Localize.string("common_error_mobile_format")
        case .valid, .none:
            ""
        }
    }

    func nameError() -> String {
        switch onEnum(of: nameResult) {
        case .conjunctiveBlank:
            Localize.string("register_name_format_error_conjunctive_blank")
        case .emptyAccountName:
            Localize.string("common_field_must_fill")
        case .exceededLength:
            Localize.string("register_name_format_error_length_limitation", "\(maxNameLength)")
        case .forbiddenLanguage:
            Localize.string("register_name_format_error_only_vn_eng")
        case .forbiddenNumberOrSymbol:
            Localize.string("register_name_format_error_no_number_symbol")
        case .headOrTailBlank:
            Localize.string("register_name_format_error_blank_before_and_after")
        case .invalidNameFormat:
            Localize.string("register_step2_name_format_error")
        case .none:
            ""
        }
    }
}

struct RegisterStep2View_Active_Previews: PreviewProvider {
    @State private static var accountType: AccountType = .phone
    static var previews: some View {
        Content(
            accountType: $accountType,
            otpStatus: .init(isMailActive: true, isSmsActive: true),
            state: .init(),
            mobileErrorType: nil,
            emailErrorType: nil,
            onInputChange: { _ in },
            requestRegister: { _, _, _, _ in }
        )
    }
}

struct RegisterStep2View_Inactive_Previews: PreviewProvider {
    @State private static var accountType: AccountType = .phone
    static var previews: some View {
        Content(
            accountType: $accountType,
            otpStatus: .init(isMailActive: false, isSmsActive: false),
            state: .init(),
            mobileErrorType: nil,
            emailErrorType: nil,
            onInputChange: { _ in },
            requestRegister: { _, _, _, _ in }
        )
    }
}
