import Combine
import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import RxSwiftExt
import sharedbu

class ResetPasswordStep1Object: ComposeObservableObject<ResetPasswordStep1Object.Event> {
    enum Event {
        case exceedResendLimit(AccountType)
        case moveToNextStep(AccountType, String)
    }

    struct State {
        var locale: SupportLocale = .Vietnam()
        var isProcessing = false
        var lockUntil: Date? = nil
        private(set) var mobileErrorMessageKey: String? = nil
        private(set) var emailErrorMessageKey: String? = nil
        var retryCount: Int = 0
        var remainLockSecond: Int? {
            guard let lockUntil else { return nil }
            let countDownSeconds = Int(ceil(lockUntil.timeIntervalSince1970 - Date().timeIntervalSince1970))
            if countDownSeconds <= 0 {
                return nil
            }
            return countDownSeconds
        }

        func isOverRetryLimit() -> Bool {
            retryCount >= ResetPasswordStep1Object.RetryLimit
        }

        mutating func setErrorMessage(_ type: AccountType, _ message: String?) {
            switch type {
            case .phone:
                mobileErrorMessageKey = message
            case .email:
                emailErrorMessageKey = message
            }
        }
    }

    private static let RetryLimit = 11
    private static let RetryCountDownTime = 60

    @Injected private var systemUseCase: ISystemStatusUseCase
    @Injected private var resetUseCase: ResetPasswordUseCase
    @Injected private var playerConfiguration: PlayerConfiguration
    private let countDownTimer = CountDownTimer()
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var state: State = .init()
    @Published var accountType: AccountType = .phone
    @Published private(set) var otpStatus: OtpStatus = .init(isMailActive: true, isSmsActive: true)

    override init() {
        super.init()
        state = State(
            locale: playerConfiguration.supportLocale,
            lockUntil: resetUseCase.getCountDownEndTime(),
            retryCount: resetUseCase.getRetryCount()
        )
    }

    func clearErrorMessage(_ accountType: AccountType) {
        state.setErrorMessage(accountType, nil)
    }

    func refreshOtpStatus() {
        systemUseCase.isOtpBlocked()
            .subscribe(
                onSuccess: { [unowned self] status in otpStatus = status },
                onFailure: { [unowned self] err in publisher = .error(err) }
            )
            .disposed(by: disposeBag)
    }

    func requestPasswordReset(_ type: AccountType, _ identity: String) {
        state.isProcessing = true

        let account = switch type {
        case .phone:
            Account.Phone(phone: identity, locale: state.locale)
        case .email:
            Account.Email(email: identity)
        }

        resetUseCase.forgetPassword(account: account)
            .subscribe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [unowned self] in
                resetUseCase.setCountDownEndTime(date: nil)
                resetUseCase.setRetryCount(count: 0)
                publisher = .event(.moveToNextStep(type, identity))
            }, onError: { [unowned self] err in
                state.retryCount += 1
                resetUseCase.setRetryCount(count: state.retryCount)
                handleError(type, err)
            }, onDisposed: { [unowned self] in
                state.isProcessing = false
            })
            .disposed(by: disposeBag)
    }

    private func handleError(_ accountType: AccountType, _ error: Error) {
        switch error {
        case is PlayerIsInactive,
             is PlayerIsLocked,
             is PlayerIsNotExist,
             is PlayerIsSuspend:
            if state.isOverRetryLimit() {
                state.setErrorMessage(accountType, "common_error_try_later")
                lockResetButton()
            } else {
                let message: String = switch accountType {
                case .phone:
                    "common_error_phone_verify"
                case .email:
                    "common_error_email_verify"
                }
                state.setErrorMessage(accountType, message)
            }
        case is PlayerIdOverOtpLimit,
             is PlayerIpOverOtpDailyLimit,
             is PlayerOverOtpRetryLimit:
            publisher = .event(.exceedResendLimit(accountType))
        case is PlayerOtpMailInactive,
             is PlayerOtpSmsInactive:
            refreshOtpStatus()
        default:
            publisher = .error(error)
        }
    }

    private func lockResetButton() {
        state.lockUntil = Date().adding(value: ResetPasswordStep1Object.RetryCountDownTime, byAdding: .second)
        resetUseCase.setCountDownEndTime(date: state.lockUntil)
    }
}

class AccountVerification: ObservableObject {
    enum VerificationState {
        case empty
        case invalidFormat
        case valid
    }

    struct AccountState: Equatable {
        private(set) var locale: SupportLocale
        private(set) var accountType: AccountType
        var areaCode: String { "+" + locale.cellPhoneNumberFormat().areaCode() + " " }

        var identity: String? = nil

        var rawIdentity: String? {
            if accountType == .phone {
                identity?.deletingPrefix(areaCode)
            } else {
                identity
            }
        }

        private var accountVerifier: AccountPatternGenerator {
            AccountPatternGeneratorFactory.create(locale)
        }

        var isIdentityValid: Bool {
            switch accountType {
            case .phone:
                isMobileValid() == .valid
            case .email:
                isEmailValid() == .valid
            }
        }

        func isEmailValid() -> VerificationState? {
            guard let identity else { return nil }
            switch identity {
            case let identity where identity.isEmpty:
                return .empty
            case let identity where !Account.Email(email: identity).isValid():
                return .invalidFormat
            default:
                return .valid
            }
        }

        func isMobileValid() -> VerificationState? {
            guard let identity else { return nil }

            let rawMobile = identity.deletingPrefix(areaCode)
            switch rawMobile {
            case let rawMobile where rawMobile.isEmpty:
                return .empty
            case let rawMobile where !accountVerifier.mobileNumber().verifyFormat(number: rawMobile):
                return .invalidFormat
            default:
                return .valid
            }
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
            if accountType == .phone, state.identity != nil,
               !state.identity!.hasPrefix(state.areaCode)
            {
                state.identity = state.areaCode
            }
        }
    }
}
