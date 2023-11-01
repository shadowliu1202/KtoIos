import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import RxSwiftExt
import sharedbu

class ResetPasswordViewModel: CollectErrorViewModel {
  private let resetUseCase: ResetPasswordUseCase
  private let systemUseCase: ISystemStatusUseCase
  private let localStorageRepo: LocalStorageRepository
  
  private let disposeBag = DisposeBag()
  
  private let otpStatusRefreshSubject = PublishSubject<Void>()
  
  private var phoneEdited = false
  private var mailEdited = false
  private var passwordEdited = false
  
  var relayEmail = BehaviorRelay(value: "")
  var relayMobile = BehaviorRelay(value: "")
  var relayPassword = BehaviorRelay(value: "")
  var relayConfirmPassword = BehaviorRelay(value: "")
  
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

  init(
    _ resetUseCase: ResetPasswordUseCase,
    _ systemUseCase: ISystemStatusUseCase,
    _ localStorageRepo: LocalStorageRepository)
  {
    self.resetUseCase = resetUseCase
    self.systemUseCase = systemUseCase
    self.localStorageRepo = localStorageRepo
  }

  func event() -> (
    otpStatus: Driver<OtpStatus>,
    emailValid: Observable<UserInfoStatus>,
    mobileValid: Observable<UserInfoStatus>,
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
    
    let otpStatus = otpStatusRefreshSubject
      .flatMapLatest { [weak self] _ -> Single<OtpStatus?> in
        guard let self
        else {
          return .just(nil)
        }
        
        return self.systemUseCase
          .fetchOTPStatus()
          .map { $0 }
          .catch { [weak self] error in
            self?.errorsSubject
              .onNext(error)
            
            return .just(nil)
          }
      }
      .compactMap { $0 }
      .asDriverOnErrorJustComplete()

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
      otpStatus: otpStatus,
      emailValid: emailValid,
      mobileValid: mobileValid,
      passwordValid: passwordValid)
  }

  func refreshOtpStatus() {
    otpStatusRefreshSubject.onNext(())
  }

  func requestPasswordReset(_ selectedVerifyWay: AccountType) -> Completable {
    let account = selectedVerifyWay == .phone
      ? Account.Phone(phone: relayMobile.value, locale: locale)
      : Account.Email(email: relayEmail.value)
    
    return resetUseCase.forgetPassword(account: account)
  }

  func inputLocale(_ locale: SupportLocale) {
    self.locale = locale
  }

  func getAccount(_ selectedVerifyWay: AccountType) -> String {
    selectedVerifyWay == .phone ? relayMobile.value : relayEmail.value
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
  
  func getSupportLocale() -> SupportLocale {
    localStorageRepo.getSupportLocale()
  }
}
