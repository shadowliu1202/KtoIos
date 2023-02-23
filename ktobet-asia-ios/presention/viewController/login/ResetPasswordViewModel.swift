import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import SharedBu

class ResetPasswordViewModel {
  static let accountRetryLimit = 11
  static let retryCountDownTime = 60
  private var resetUseCase: ResetPasswordUseCase!
  private var systemUseCase: GetSystemStatusUseCase!
  private let localStorageRepo: LocalStorageRepository
  private var phoneEdited = false
  private var mailEdited = false
  private var passwordEdited = false
  var relayEmail = BehaviorRelay(value: "")
  var relayMobile = BehaviorRelay(value: "")
  var relayPassword = BehaviorRelay(value: "")
  var relayConfirmPassword = BehaviorRelay(value: "")
  var relayAccountType = BehaviorRelay(value: AccountType.phone)
  var remainTime = 0
  var retryCount: Int {
    get {
      resetUseCase.getRetryCount()
    }
    set {
      resetUseCase.setRetryCount(count: newValue)
    }
  }

  var otpRetryCount: Int {
    get {
      resetUseCase.getOtpRetryCount()
    }
    set {
      resetUseCase.setOtpRetryCount(count: newValue)
    }
  }

  var countDownEndTime: Date? {
    get {
      resetUseCase.getCountDownEndTime()
    }
    set {
      resetUseCase.setCountDownEndTime(date: newValue)
    }
  }

  lazy var locale = localStorageRepo.getSupportLocale()

  private var otpStatusRefreshSubject = PublishSubject<Void>()
  private let otpStatus: ReplaySubject<OtpStatus> = .create(bufferSize: 1)
  private let disposeBag = DisposeBag()

  init(
    _ resetUseCase: ResetPasswordUseCase,
    _ systemUseCase: GetSystemStatusUseCase,
    _ localStorageRepo: LocalStorageRepository)
  {
    self.resetUseCase = resetUseCase
    self.systemUseCase = systemUseCase
    self.localStorageRepo = localStorageRepo

    otpStatusRefreshSubject.asObservable()
      .flatMapLatest { [unowned self] in self.systemUseCase.getOtpStatus().asObservable() }
      .bind(to: otpStatus)
      .disposed(by: disposeBag)
  }

  func currentAccountType() -> AccountType {
    relayAccountType.value
  }

  func inputAccountType(_ type: AccountType) {
    refreshOtpStatus()
    relayAccountType.accept(type)
  }

  func event() -> (
    otpValid: Observable<UserInfoStatus>,
    accountValid: Observable<Bool>,
    emailValid: Observable<UserInfoStatus>,
    mobileValid: Observable<UserInfoStatus>,
    typeChange: Observable<AccountType>,
    passwordValid: Observable<UserInfoStatus>)
  {
    let emailValid = relayEmail
      .map { text -> UserInfoStatus in
        let valid = Account.Email(email: text).isValid()
        if text.count > 0 { self.mailEdited = true }
        if valid { return .valid }
        else if text.count == 0 {
          if self.mailEdited { return .empty }
          else { return .firstEmpty }
        }
        else { return .errEmailFormat }
      }

    let mobileValid = relayMobile
      .map { text -> UserInfoStatus in
        let valid = Account.Phone(phone: text, locale: self.locale).isValid()
        if text.count > 0 { self.phoneEdited = true }
        if valid { return .valid }
        else if text.count == 0 {
          if self.phoneEdited { return .empty }
          else { return .firstEmpty }
        }
        else { return .errPhoneFormat }
      }

    let typeChange = relayAccountType.asObservable()
    let otpValid = Observable.combineLatest(otpStatus, typeChange)
      .map { otpStatus, type -> UserInfoStatus in
        switch type {
        case .email: return otpStatus.isMailActive ? .valid : .errEmailOtpInactive
        case .phone: return otpStatus.isSmsActive ? .valid : .errSMSOtpInactive
        }
      }

    let accountValid = Observable.combineLatest(typeChange, emailValid, mobileValid) {
      (
        ($0 == AccountType.email && $1 == UserInfoStatus.valid) ||
          ($0 == AccountType.phone && $2 == UserInfoStatus.valid)) && self.remainTime == 0
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

    return (
      otpValid: otpValid,
      accountValid: accountValid,
      emailValid: emailValid,
      mobileValid: mobileValid,
      typeChange: typeChange,
      passwordValid: passwordValid)
  }

  func refreshOtpStatus() {
    otpStatusRefreshSubject.onNext(())
  }

  func requestPasswordReset() -> Completable {
    let account = relayAccountType.value == .phone ? Account.Phone(phone: relayMobile.value, locale: locale) :
      Account.Email(email: relayEmail.value)
    return resetUseCase.forgetPassword(account: account)
  }

  func inputLocale(_ locale: SupportLocale) {
    self.locale = locale
  }

  func getAccount() -> String {
    relayAccountType.value == .phone ? relayMobile.value : relayEmail.value
  }

  func verifyResetOtp(otpCode: String) -> Completable {
    resetUseCase.verifyResetOtp(otp: otpCode)
  }

  func resendOtp() -> Completable {
    resetUseCase.resendOtp()
  }

  func doResetPassword() -> Completable {
    resetUseCase.resetPassword(password: relayPassword.value)
  }
}
