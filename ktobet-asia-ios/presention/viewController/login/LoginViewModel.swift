import Foundation
import RxCocoa
import RxSwift
import SharedBu

class LoginViewModel {
  enum LoginDataStatus {
    case valid
    case firstEmpty
    case empty
    case invalid
  }

  private var authUseCase: AuthenticationUseCase!
  private var configUseCase: ConfigurationUseCase!
  private var accountEdited = false
  private var passwordEdited = false
  private var timerOverLoginLimit = CountDownTimer()

  lazy var relayAccount = BehaviorRelay(value: authUseCase.getRememberAccount())
  var relayPassword = BehaviorRelay(value: "")
  var relayCaptcha = BehaviorRelay(value: "")
  var relayOverLoginLimit = BehaviorRelay(value: false)
  var relayCountDown = BehaviorRelay(value: 0)
  var relayImgCaptcha = BehaviorRelay<UIImage?>(value: nil)

  init(
    _ authenticationUseCase: AuthenticationUseCase,
    _ configurationUseCase: ConfigurationUseCase)
  {
    authUseCase = authenticationUseCase
    configUseCase = configurationUseCase
  }

  func refresh() {
    relayAccount.accept(relayAccount.value)
    relayPassword.accept(relayPassword.value)
    relayCaptcha.accept(relayCaptcha.value)
    relayOverLoginLimit.accept(relayOverLoginLimit.value)
    relayCountDown.accept(relayCountDown.value)
    relayImgCaptcha.accept(relayImgCaptcha.value)
  }

  func continueLoginLimitTimer() {
    var lastLoginLimitDate = authUseCase.getLastOverLoginLimitDate()
    let count = Int(ceil(lastLoginLimitDate.timeIntervalSince1970 - Date().timeIntervalSince1970))
    if count <= 0 {
      let date = Date()
      authUseCase.setLastOverLoginLimitDate(date)
      lastLoginLimitDate = date
    }
    relayOverLoginLimit.accept(true)
    relayCountDown.accept(count)
    timerOverLoginLimit
      .start(timeInterval: 1, endTime: lastLoginLimitDate, block: { _, countDown, finish in
        self.relayCountDown.accept(countDown)
        if finish {
          self.relayOverLoginLimit.accept(false)
        }
      })
  }

  func launchLoginLimitTimer() {
    let lastLoginLimitDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
    authUseCase.setLastOverLoginLimitDate(lastLoginLimitDate)
    relayOverLoginLimit.accept(true)
    relayCountDown.accept(60)
    timerOverLoginLimit
      .start(timeInterval: 1, endTime: lastLoginLimitDate, block: { _, countDown, finish in
        self.relayCountDown.accept(countDown)
        if finish {
          self.relayOverLoginLimit.accept(false)
        }
      })
  }

  func stopLoginLimitTimer() {
    timerOverLoginLimit.stop()
  }

  func login() -> Single<Player> {
    let account = self.relayAccount.value.trimmingCharacters(in: .whitespaces)
    let password = self.relayPassword.value
    let captcha = Captcha(passCode: self.relayCaptcha.value)
    return authUseCase.login(account: account, pwd: password, captcha: captcha)
  }

  func getCaptchaImage() -> Single<UIImage> {
    authUseCase
      .getCaptchaImage()
      .map { img -> UIImage in
        self.authUseCase.setNeedCaptcha(true)
        self.relayImgCaptcha.accept(img)
        return img
      }
  }

  func event() -> (
    accountValid: Observable<LoginDataStatus>,
    passwordValid: Observable<LoginDataStatus>,
    captchaValid: Observable<Bool>,
    captchaImage: Observable<UIImage?>,
    dataValid: Observable<Bool>,
    countDown: Observable<Int>)
  {
    let accountValid = relayAccount
      .map { text -> LoginDataStatus in
        if text.count > 0 { self.accountEdited = true }
        if text.count > 0 { return .valid }
        else { return self.accountEdited ? .empty : .firstEmpty }
      }

    let passwordValid = relayPassword.map { text -> LoginDataStatus in
      if text.count > 0 { self.passwordEdited = true }
      if text.count >= 6 { return .valid }
      else if text.count == 0 { return self.passwordEdited ? .empty : .firstEmpty }
      else { return .invalid }
    }

    let image: Observable<UIImage?> = {
      if authUseCase.getNeedCaptcha() {
        return getCaptchaImage()
          .asObservable()
          .flatMap { image -> Observable<UIImage?> in
            self.relayImgCaptcha.accept(image)
            return self.relayImgCaptcha.asObservable()
          }
      }
      else {
        return self.relayImgCaptcha.asObservable()
      }
    }()

    let limit = relayOverLoginLimit.asObservable()
    let captchaValid = relayImgCaptcha
      .asObservable()
      .flatMapLatest { captchaImg -> Observable<Bool> in
        self.relayCaptcha
          .asObservable()
          .map { captcha -> Bool in
            guard captchaImg != nil else {
              return true
            }
            return captcha.count > 0
          }
      }
    let dataValid = Observable.combineLatest(accountValid, passwordValid, limit, captchaValid) {
      $0 == LoginDataStatus.valid && $1 == LoginDataStatus.valid && !$2 && $3
    }
    return (
      accountValid: accountValid,
      passwordValid: passwordValid,
      captchaValid: captchaValid,
      captchaImage: image,
      dataValid: dataValid,
      countDown: relayCountDown.asObservable())
  }
}
