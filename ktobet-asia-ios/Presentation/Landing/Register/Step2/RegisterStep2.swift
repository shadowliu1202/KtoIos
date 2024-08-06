import Combine
import Foundation
import RxSwift
import sharedbu
import SwiftUI

class RegisterStep2: ComposeObservableObject<RegisterStep2.Event> {
    enum Event {
        case blocked, proceedRegistration(AccountType, identity:String, password:String)
    }

    struct State {
        var locale: SupportLocale = .Vietnam()
        var isProcessing: Bool = false
        var mobileErrorMessage: String? = nil
        var emailErrorMessage: String? = nil
    }

    @Injected private var registerUseCase: RegisterUseCase
    @Injected private var systemUseCase: ISystemStatusUseCase
    @Injected private var accountPatternGenerator: AccountPatternGenerator
    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var supportLocale: SupportLocale
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published var accountType: AccountType = .phone
    @Published private(set) var otpStatus: OtpStatus = .init(isMailActive: true, isSmsActive: true)
    @Published var state: State = .init()

    override init() {
        super.init()
        state = .init(locale: supportLocale)

        systemUseCase.isOtpBlocked()
            .subscribe(
                onSuccess: { [unowned self] status in
                    otpStatus = status
                    if !status.isSmsActive { accountType = .email }
                },
                onFailure: { [unowned self] error in publisher = .error(error) }
            )
            .disposed(by: disposeBag)
    }

    func clearErrorMessage(_ accountType: AccountType) {
        switch accountType {
        case .phone:
            state.mobileErrorMessage = nil
        case .email:
            state.emailErrorMessage = nil
        }
    }

    func requestRegister(_ accountType: AccountType, _ identity: String, _ withdrawalName: String, _ password: String) {
        state.isProcessing = true
        let account = switch accountType {
        case .phone:
            Account.Phone(phone: identity, locale: supportLocale)
        case .email:
            Account.Email(email: identity)
        }
        registerUseCase.register(
            account: UserAccount(username: withdrawalName, type: account),
            password: UserPassword(value: password),
            locale: supportLocale
        )
        .subscribe(
            onCompleted: { [unowned self] in publisher = .event(.proceedRegistration(accountType, identity: identity, password: password))  },
            onError: { [unowned self] error in handleErrors(accountType, error) },
            onDisposed: { [unowned self] in state.isProcessing = false }
        )
        .disposed(by: disposeBag)
    }

    func handleErrors(_ accountType: AccountType, _ error: Error) {
        switch error {
        case is PlayerIpOverOtpDailyLimit:
            switch accountType {
            case .phone: state.mobileErrorMessage = Localize.string("common_email_otp_exeed_send_limit")
            case .email: state.emailErrorMessage = Localize.string("common_email_otp_exeed_send_limit")
            }
        case is DBPlayerAlreadyExist:
            switch accountType {
            case .phone: state.mobileErrorMessage = Localize.string("common_error_phone_verify")
            case .email: state.emailErrorMessage = Localize.string("common_error_email_verify")
            }
        case is PlayerOtpMailInactive, is PlayerOtpSmsInactive:
            refreshOtpStatus()
        case is KtoPlayerRegisterBlock:
            publisher = .event(.blocked)
        default:
            publisher = .error(error)
        }
    }

    private func refreshOtpStatus() {
        systemUseCase.isOtpBlocked()
            .subscribe(
                onSuccess: { [unowned self] status in otpStatus = status },
                onFailure: { [unowned self] error in publisher = .error(error) }
            )
            .disposed(by: disposeBag)
    }
}

class RegisterStep2Account: ObservableObject {
    struct AccountState: Equatable {
        private(set) var locale: SupportLocale
        private(set) var accountType: AccountType
        private(set) var isActive: Bool = true
        var areaCode: String { "+" + locale.cellPhoneNumberFormat().areaCode() + " " }

        var identity: String? = nil
        var name: String? = nil
        var password: String? = nil
        var passwordConfirm: String? = nil

        private var accountVerifier: AccountPatternGenerator {
            AccountPatternGeneratorFactory.create(locale)
        }

        enum IdentityResult {
            case empty, invalidFormat, valid
        }

        var nonPrefixIdentity: String? {
            if accountType == .phone {
                identity?.deletingPrefix(areaCode)
            } else {
                identity
            }
        }

        var identityResult: IdentityResult? {
            switch accountType {
            case .phone:
                isMobileValid(mobile: identity)
            case .email:
                isEmailValid(email: identity)
            }
        }

        private func isEmailValid(email: String?) -> IdentityResult? {
            guard let email else { return nil }
            return switch email {
            case let email where email.isEmpty:
                .empty
            case let email where !Account.Email(email: email).isValid():
                .invalidFormat
            default:
                .valid
            }
        }

        private func isMobileValid(mobile: String?) -> IdentityResult? {
            guard let mobile else { return nil }

            let nonPrefixMobile: String = if let spaceIndex = mobile.firstIndex(of: " ") {
                String(mobile[mobile.index(after: spaceIndex)...])
            } else {
                mobile
            }

            return switch nonPrefixMobile {
            case let mobile where mobile.isEmpty:
                .empty
            case let mobile where !accountVerifier.mobileNumber().verifyFormat(number: mobile):
                .invalidFormat
            default:
                .valid
            }
        }

        var nameResult: AccountNameException? {
            guard let name else { return nil }
            return accountVerifier.withdrawalName().validate(name: name)
        }

        var maxNameLength: Int32 {
            accountVerifier.withdrawalName().maxLength
        }

        enum PasswordResult {
            case empty, invalidFormat, notMatch, valid
        }

        var passwordResult: PasswordResult? {
            if password == nil && passwordConfirm == nil { return nil }

            return if password == nil || password!.isEmpty {
                .empty
            } else if !UserPassword.companion.verify(password: password!) {
                .invalidFormat
            } else if password != passwordConfirm {
                .notMatch
            } else {
                nil
            }
        }

        var isSubmitValid: Bool {
            identity != nil && name != nil && password != nil && passwordConfirm != nil && identityResult == .valid && nameResult == nil && passwordResult == nil
        }
    }

    init(locale: SupportLocale, accountType: AccountType) {
        state = .init(locale: locale, accountType: accountType)
        self.locale = locale
        self.accountType = accountType
    }

    private let accountType: AccountType
    private let locale: SupportLocale

    @Published var state: AccountState {
        didSet {
            if accountType == .phone, state.identity != nil, !state.identity!.hasPrefix(state.areaCode) { state.identity = state.areaCode }
        }
    }
}
