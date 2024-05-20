import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import sharedbu

class SignupUserInfoViewModel {
    enum AccountType {
        case phone
        case email
    }

    enum UserInfoStatus {
        case valid
        case firstEmpty
        case empty
        case errNameFormat
        case errEmailFormat
        case errPhoneFormat
        case errPasswordFormat
        case errPasswordNotMatch
        case errEmailOtpInactive
        case errSMSOtpInactive
        case doNothing
    }

    private var usecaseRegister: RegisterUseCase!
    private var usecaseSystemStatus: ISystemStatusUseCase!

    private var phoneEdited = false
    private var mailEdited = false
    private var passwordEdited = false
    private var nameEdited = false
    private var otpStatusRefreshSubject = PublishSubject<Void>()
    private let otpStatus: ReplaySubject<OtpStatus> = .create(bufferSize: 1)
    private let disposeBag = DisposeBag()

    var accountPatternGenerator: AccountPatternGenerator!
    var relayName = BehaviorRelay(value: "")
    var relayEmail = BehaviorRelay(value: "")
    var relayMobile = BehaviorRelay(value: "")
    var relayPassword = BehaviorRelay(value: "")
    var relayConfirmPassword = BehaviorRelay(value: "")
    var relayAccountType = BehaviorRelay(value: AccountType.phone)
    var locale: SupportLocale = .China()

    init(
        _ usecaseRegister: RegisterUseCase,
        _ usecaseSystem: ISystemStatusUseCase,
        _ accountPatternGenerator: AccountPatternGenerator)
    {
        self.usecaseRegister = usecaseRegister
        self.usecaseSystemStatus = usecaseSystem
        self.accountPatternGenerator = accountPatternGenerator

        otpStatusRefreshSubject.asObservable()
            .flatMapLatest { [unowned self] in self.usecaseSystemStatus.fetchOTPStatus().asObservable() }
            .bind(to: otpStatus)
            .disposed(by: disposeBag)
    }

    func inputAccountType(_ type: AccountType) {
        relayAccountType.accept(type)
        refreshOtpStatus()
    }

    func inputLocale(_ locale: SupportLocale) {
        self.locale = locale
    }

    func currentAccountType() -> AccountType {
        relayAccountType.value
    }

    func currentPassword() -> String {
        relayPassword.value
    }

    private lazy var nameValidator = RealNameValidator(
        editAccountName: relayName,
        accountPatternGenerator: self.accountPatternGenerator)

    func event() -> (
        otpValid: Observable<OtpStatus>,
        emailValid: Observable<UserInfoStatus>,
        mobileValid: Observable<UserInfoStatus>,
        nameValid: Observable<AccountNameException?>,
        passwordValid: Observable<UserInfoStatus>,
        dataValid: Observable<Bool>,
        typeChange: Observable<AccountType>)
    {
        let nameValid = nameValidator.isAccountNameValid.map { $0 ? UserInfoStatus.valid : .errNameFormat }
        let nameValidException = nameValidator.verifyAccountNameError

        let emailValid = relayAccountType
            .flatMapLatest { type -> Observable<UserInfoStatus> in
                self.relayEmail.map { text -> UserInfoStatus in
                    guard type == .email else {
                        return .doNothing
                    }
                    let valid = Account.Email(email: text).isValid()
                    if text.count > 0 { self.mailEdited = true }
                    if valid { return .valid }
                    else if text.count == 0 {
                        if self.mailEdited { return .empty }
                        else { return .firstEmpty }
                    }
                    else { return .errEmailFormat }
                }
            }

        let mobileValid = relayAccountType.flatMapLatest { type -> Observable<UserInfoStatus> in
            self.relayMobile
                .map { text -> UserInfoStatus in
                    guard type == .phone else {
                        return .doNothing
                    }
                    let valid = Account.Phone(phone: text, locale: self.locale).isValid()
                    if text.count > 0 { self.phoneEdited = true }
                    if valid { return .valid }
                    else if text.count == 0 {
                        if self.phoneEdited { return .empty }
                        else { return .firstEmpty }
                    }
                    else { return .errPhoneFormat }
                }
        }

        let password = relayPassword.asObservable()
        let confirmPassword = relayConfirmPassword.asObservable()
        let passwordValid = password
            .flatMapLatest { passwordText in
                confirmPassword.map { confirmPasswordText -> UserInfoStatus in
                    let valid = UserPassword.Companion().verify(password: passwordText)
                    if passwordText.count > 0 { self.passwordEdited = true }
                    if passwordText.count == 0 {
                        if self.passwordEdited { return .empty }
                        else { return .firstEmpty }
                    }
                    else if !valid {
                        return .errPasswordFormat
                    }
                    else if passwordText != confirmPasswordText {
                        return .errPasswordNotMatch
                    }
                    else {
                        return .valid
                    }
                }
            }

        let typeChange = relayAccountType.asObservable()

        let accountValid = Observable.combineLatest(typeChange, emailValid, mobileValid) {
            ($0 == AccountType.email && $1 == UserInfoStatus.valid) ||
                ($0 == AccountType.phone && $2 == UserInfoStatus.valid)
        }

        let dataValid = Observable
            .combineLatest(nameValid, accountValid, passwordValid) {
                ($0 == UserInfoStatus.valid) && $1 && ($2 == UserInfoStatus.valid)
            }

        let otpValid = otpStatus

        return (
            otpValid: otpValid,
            emailValid: emailValid,
            mobileValid: mobileValid,
            nameValid: nameValidException,
            passwordValid: passwordValid,
            dataValid: dataValid,
            typeChange: typeChange)
    }

    func refreshOtpStatus() {
        otpStatusRefreshSubject.onNext(())
    }

    func register() -> Single<(type: AccountType, account: String, password: String)> {
        let userAccount: UserAccount = {
            switch relayAccountType.value {
            case .phone:
                return UserAccount(username: relayName.value, type: Account.Phone(phone: relayMobile.value, locale: locale))
            case .email:
                return UserAccount(username: relayName.value, type: Account.Email(email: relayEmail.value))
            }
        }()
        let userPassword = UserPassword(value: relayPassword.value)
        let nextAction = Single<(type: AccountType, account: String, password: String)>
            .create { single -> Disposable in
                var account = ""
                let password = self.relayPassword.value
                switch self.relayAccountType.value {
                case .phone: account = self.relayMobile.value
                case .email: account = self.relayEmail.value
                }
                single(.success((self.relayAccountType.value, account, password)))
                return Disposables.create { }
            }
        return usecaseRegister
            .register(account: userAccount, password: userPassword, locale: self.locale)
            .andThen(nextAction)
    }
}
