import Foundation
import RxSwift
import RxCocoa
import SharedBu

class ModifyProfileViewModel: KTOViewModel {
    private var playerUseCase: PlayerDataUseCase!
    private var configurationUseCase: ConfigurationUseCase!
    private var withdrawalUseCase: WithdrawalUseCase!
    private var accountPatternGenerator: AccountPatternGenerator!

    var relayPassword = BehaviorRelay(value: "")
    lazy var isAffiliateMember = playerUseCase.isAffiliateMember()
    lazy var supportLocale: SupportLocale = configurationUseCase.locale()
    lazy var profileAuthorization: Single<AuthenticationState> = playerUseCase.checkProfileEditable().map({
        return $0 ? AuthenticationState.authenticated : AuthenticationState.unauthenticated
    })
    lazy var playerProfile = PublishSubject<PlayerProfile>()
    lazy var emailState: Observable<EditableContent<String?>> = playerProfile.map({ $0.email })
    lazy var mobileState: Observable<EditableContent<String?>> = playerProfile.map({ $0.mobile })
    lazy var isAnyWithdrawalTicketApplying = withdrawalUseCase.isAnyTicketApplying()
    
    // MARK: Change password
    var relayChangePassword = BehaviorRelay(value: "")
    var relayConfirmPassword = BehaviorRelay(value: "")
    private lazy var newPasswordValidator: NewPasswordValidator = {
        return NewPasswordValidator(accountPassword: self.relayChangePassword, confirmPassword: self.relayConfirmPassword)
    }()
    lazy var passwordValidationError: Observable<UserInfoStatus> = self.newPasswordValidator.passwordValidationError
    lazy var isPasswordValid: Observable<Bool> = self.newPasswordValidator.isPasswordValid
    
    // MARK: Change withdrrawal real name
    var relayRealName = BehaviorRelay(value: "")
    private lazy var realNameValidator: RealNameValidator = {
        return RealNameValidator(editAccountName: relayRealName, accountPatternGenerator: self.accountPatternGenerator)
    }()
    lazy var verifyAccountNameError: Observable<AccountNameException?> = self.realNameValidator.verifyAccountNameError
    lazy var isAccountNameValid: Observable<Bool> = self.realNameValidator.isAccountNameValid.startWith(false)
    lazy var accountNameMaxLength = self.accountPatternGenerator.withdrawalName().maxLength
    
    // MARK: set birthday
    lazy var locale = playerUseCase.getLocale()
    var relayBirthdayDate: BehaviorRelay<Date?> = BehaviorRelay(value: nil)
    private lazy var birthdayValidator: BirthdayValidator = {
        return BirthdayValidator()
    }()
    
    init(_ playerDataUseCase: PlayerDataUseCase,
         _ configurationUseCase: ConfigurationUseCase,
         _ withdrawalUseCase: WithdrawalUseCase,
         _ accountPatternGenerator: AccountPatternGenerator) {
        super.init()
        self.playerUseCase = playerDataUseCase
        self.configurationUseCase = configurationUseCase
        self.withdrawalUseCase = withdrawalUseCase
        self.accountPatternGenerator = accountPatternGenerator
    }

    func fetchPlayerProfile() -> Single<Void> {
        return profileAuthorization.flatMap({ [unowned self] in
            if $0 == . authenticated {
                return self.playerUseCase.loadPlayerProfile()
            }
            return Single<PlayerProfile>.just(PlayerProfile())
        }).flatMap({ [unowned self] (profile: PlayerProfile) -> Single<Void> in
            self.playerProfile.onNext(profile)
            return Single.just(())
        })
    }

    func authorizeProfileSetting(password: String) -> Completable {
        return playerUseCase.authorizeProfileEdition(password: password).asObservable().ignoreElements()
    }

    func changePassword(password: String) -> Completable {
        return playerUseCase.changePassword(password: password)
    }

    func verifyOldAccount(accountType: AccountType) -> Completable {
        playerUseCase.verifyOldAccount(accountType).compose(self.applyCompletableErrorHandler())
    }

    func modifyWithdrawalName(name: String) -> Completable {
        return playerUseCase.setWithdrawalName(name: name)
    }
    
    func validateBirthday(_ date: Date?) -> BithdayValidError {
        return birthdayValidator.validateBirthday(date)
    }
    
    func modifyBirthday(birthDay: String?) -> Completable {
        if let date = birthDay?.toDate(format: "yyyy/MM/dd", timeZone: Foundation.TimeZone(abbreviation: "UTC")!) {
            return playerUseCase.setBirthDay(birthDay: date)
        }
        return Completable.error(KTOError.EmptyData)
    }
    
    func verifyOldOtp(otp: String, accountType: AccountType) -> Completable {
        playerUseCase.verifyOldAccountOtp(otp, accountType)
    }
    
    func resendOtp(accountType: AccountType) -> Completable {
        playerUseCase.resendOtp(accountType)
    }
    
    func modifyEmail(email: String) -> Completable {
        playerUseCase.setEmail(email).compose(self.applyCompletableErrorHandler())
    }
    
    func modifyMobile(mobile: String) -> Completable {
        playerUseCase.setMobile(mobile).compose(self.applyCompletableErrorHandler())
    }
    
    var otpRetryCount: Int {
        get {
            configurationUseCase.getOtpRetryCount()
        }
        set {
            configurationUseCase.setOtpRetryCount(newValue)
        }
    }
    
    func verifyNewOtp(otp: String, accountType: AccountType) -> Completable {
        playerUseCase.verifyNewAccountOtp(otp, accountType)
    }
}
