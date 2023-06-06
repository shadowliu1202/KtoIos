import Foundation
import RxCocoa
import RxSwift
import SharedBu

class ModifyProfileViewModel: CollectErrorViewModel {
  @Injected private var loading: Loading

  private var playerUseCase: PlayerDataUseCase!
  private var configurationUseCase: ConfigurationUseCase!
  private var withdrawalService: IWithdrawalAppService!
  private var accountPatternGenerator: AccountPatternGenerator!
  private var loadingTracker: ActivityIndicator { loading.tracker }

  let disposeBag = DisposeBag()

  var relayPassword = BehaviorRelay(value: "")
  lazy var isAffiliateMember = playerUseCase.isAffiliateMember()
  lazy var supportLocale: SupportLocale = configurationUseCase.locale()
  lazy var profileAuthorization: Single<AuthenticationState> = playerUseCase.checkProfileEditable().map({
    $0 ? AuthenticationState.authenticated : AuthenticationState.unauthenticated
  })
  lazy var playerProfile = PublishSubject<PlayerProfile>()
  lazy var emailState: Observable<EditableContent<String?>> = playerProfile.map({ $0.email })
  lazy var mobileState: Observable<EditableContent<String?>> = playerProfile.map({ $0.mobile })
  lazy var isAnyWithdrawalTicketApplying = Single
    .from(withdrawalService.isAnyApplyingWithdrawal())
    .map { $0.boolValue }

  // MARK: Change password
  var relayChangePassword = BehaviorRelay(value: "")
  var relayConfirmPassword = BehaviorRelay(value: "")
  private lazy var newPasswordValidator = NewPasswordValidator(
    accountPassword: self.relayChangePassword,
    confirmPassword: self.relayConfirmPassword)

  lazy var passwordValidationError: Observable<UserInfoStatus> = self.newPasswordValidator.passwordValidationError
  lazy var isPasswordValid: Observable<Bool> = self.newPasswordValidator.isPasswordValid

  // MARK: Change withdrawal real name
  var relayRealName = BehaviorRelay(value: "")
  private lazy var realNameValidator = RealNameValidator(
    editAccountName: relayRealName,
    accountPatternGenerator: self.accountPatternGenerator)

  lazy var verifyAccountNameError: Observable<AccountNameException?> = self.realNameValidator.verifyAccountNameError
  lazy var isAccountNameValid: Observable<Bool> = self.realNameValidator.isAccountNameValid.startWith(false)
  lazy var accountNameMaxLength = self.accountPatternGenerator.withdrawalName().maxLength

  // MARK: set birthday
  lazy var locale = playerUseCase.getLocale()
  var relayBirthdayDate: BehaviorRelay<Date?> = BehaviorRelay(value: nil)
  private lazy var birthdayValidator = BirthdayValidator()

  init(
    _ playerDataUseCase: PlayerDataUseCase,
    _ configurationUseCase: ConfigurationUseCase,
    _ withdrawalService: IWithdrawalAppService,
    _ accountPatternGenerator: AccountPatternGenerator)
  {
    super.init()
    self.playerUseCase = playerDataUseCase
    self.configurationUseCase = configurationUseCase
    self.withdrawalService = withdrawalService
    self.accountPatternGenerator = accountPatternGenerator
  }

  func fetchPlayerProfile() -> Single<Void> {
    profileAuthorization.flatMap({ [unowned self] in
      if $0 == .authenticated {
        return self.playerUseCase.loadPlayerProfile()
      }
      return Single<PlayerProfile>.just(PlayerProfile())
    }).flatMap({ [unowned self] (profile: PlayerProfile) -> Single<Void> in
      self.playerProfile.onNext(profile)
      return Single.just(())
    })
  }

  func authorizeProfileSetting(password: String) -> Completable {
    playerUseCase.authorizeProfileEdition(password: password).asCompletable()
  }

  func changePassword(password: String) -> Completable {
    playerUseCase.changePassword(password: password)
  }

  func verifyOldAccount(accountType: AccountType) -> Completable {
    playerUseCase.verifyOldAccount(accountType).compose(self.applyCompletableErrorHandler())
  }

  func modifyWithdrawalName(name: String) -> Completable {
    playerUseCase.setWithdrawalName(name: name)
  }

  func transformExceptionToMessage(_ e: AccountNameException?) -> String {
    AccountPatternGeneratorFactory.transform(self.accountPatternGenerator, e)
  }

  func validateBirthday(_ date: Date?) -> BithdayValidError {
    birthdayValidator.validateBirthday(date)
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
    playerUseCase.setEmail(email)
      .compose(self.applyCompletableErrorHandler())
  }

  func modifyMobile(mobile: String) -> Completable {
    playerUseCase.setMobile(mobile)
      .compose(self.applyCompletableErrorHandler())
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

  func getAffiliateHashKey() -> Single<String> {
    playerUseCase
      .getAffiliateHashKey()
      .trackOnDispose(loadingTracker)
  }

  func getAffiliateUrl(host: URL, hashKey: String) -> URL? {
    let urlString = host.absoluteString +
      "view/redirect/\(hashKey)?culture=\(supportLocale.cultureCode())&backUrl=\(host.absoluteString)"

    return URL(string: urlString)
  }
}
