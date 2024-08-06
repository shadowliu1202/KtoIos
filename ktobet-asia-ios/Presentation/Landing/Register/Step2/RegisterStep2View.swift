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
            onInputChange: viewModel.clearErrorMessage,
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
                    ))
            case let .proceedRegistration(type, identity, password):
                toastMessage(type == .phone ? Localize.string("common_otp_send_success") : Localize.string("common_otp_mail_send_success"), .success)

                moveToNext = .init(accountType: type, identity: identity, password: password)
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
    let onInputChange: (AccountType) -> Void
    let requestRegister: (AccountType, String, String, String) -> Void

    var body: some View {
        LandingViewScaffold(items: [.cs()]) {
            PageContainer(scrollable: false, bottomPadding: 0) {
                VStack(spacing: 0) {
                    Text("register_step2_title_1")
                        .localized(weight: .medium, size: 14, color: .textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("register_step2_title_2")
                        .localized(weight: .semibold, size: 24, color: .textPrimary)
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
                errorMsg: state.mobileErrorMessage,
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
                errorMsg: state.emailErrorMessage,
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
                .localized(weight: .regular, size: 14, color: .textPrimary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 30)
    }

    private struct AccountInfoForm: View {
        init(
            locale: SupportLocale,
            accountType: AccountType,
            errorMsg: String?,
            onInputChange: @escaping (AccountType) -> Void,
            submit: @escaping (AccountType, String, String, String) -> Void
        ) {
            _account = .init(wrappedValue: .init(locale: locale, accountType: accountType))
            self.errorMsg = errorMsg
            self.onInputChange = onInputChange
            self.submit = submit
        }

        @StateObject private var account: RegisterStep2Account

        let errorMsg: String?
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
                        .localized(weight: .medium, size: 14, color: .textPrimary)
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
                    .localized(weight: .regular, size: 16)
                    .disabled(!account.state.isSubmitValid)
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
    }
}

private extension RegisterStep2Account.AccountState {
    func passwordError() -> String {
        switch passwordResult {
        case .empty:
            Localize.string("common_field_must_fill")
        case .invalidFormat:
            Localize.string("common_field_format_incorrect")
        case .notMatch:
            Localize.string("register_step2_password_not_match")
        case .valid, .none:
            ""
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
            onInputChange: { _ in },
            requestRegister: { _, _, _, _ in }
        )
    }
}
