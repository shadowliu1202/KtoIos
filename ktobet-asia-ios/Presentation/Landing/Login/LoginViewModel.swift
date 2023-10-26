import Foundation
import RxSwift
import sharedbu
import SwiftUI

class LoginViewModel: ObservableObject {
  @Published var account = ""
  @Published var password = ""
  @Published var isRememberMe = false
  @Published var captchaText = ""

  @Published private(set) var loginError: LoginException? = nil
  @Published private(set) var accountErrorText = ""
  @Published private(set) var passwordErrorText = ""
  @Published private(set) var captchaErrorText = ""

  @Published private(set) var captchaImage: UIImage? = nil
  @Published private(set) var countDownSecond: Int? = nil
  @Published private(set) var disableLoginButton = true

  @Published private(set) var refreshCount = 0

  @Injected private var loading: Loading

  private let authUseCase: AuthenticationUseCase
  private let configUseCase: ConfigurationUseCase
  private let navigationViewModel: NavigationViewModel
  private let localStorageRepo: LocalStorageRepository
  private let timerOverLoginLimit = CountDownTimer()
  private let disposeBag = DisposeBag()

  private var loadingTracker: ActivityIndicator { loading.tracker }

  init(
    _ authenticationUseCase: AuthenticationUseCase,
    _ configurationUseCase: ConfigurationUseCase,
    _ navigationViewModel: NavigationViewModel,
    _ localStorageRepo: LocalStorageRepository)
  {
    authUseCase = authenticationUseCase
    configUseCase = configurationUseCase
    self.navigationViewModel = navigationViewModel
    self.localStorageRepo = localStorageRepo
  }

  func initRememberAccount() {
    let rememberAccount = localStorageRepo.getRememberAccount()
    if !rememberAccount.isEmpty {
      account = rememberAccount
      isRememberMe = true
    }
  }

  func checkNeedCaptcha() {
    if localStorageRepo.getNeedCaptcha() {
      getCaptchaImage()
    }
  }

  func checkNeedCountDown() {
    let lastOverLoginTimeLimit = localStorageRepo.getLastOverLoginLimitDate()
    if let lastOverLoginTimeLimit, lastOverLoginTimeLimit > Date() {
      launchLoginLimitTimer(lastOverLoginTimeLimit)
    }
  }

  func refreshUI() {
    refreshCount += 1
  }

  func getLoginErrorText() -> String? {
    guard let loginError else {
      return nil
    }

    switch loginError {
    case is LoginException.Failed1to5Exception:
      return Localize.string("login_invalid_username_password")
    case is LoginException.Failed6to10Exception:
      if captchaImage == nil {
        return Localize.string("login_invalid_username_password")
      }
      else {
        return Localize.string("login_invalid_username_password_captcha")
      }
    case is LoginException.AboveVerifyLimitation:
      return Localize.string("login_invalid_lockdown")
    default:
      fatalError("Should not reach here.")
    }
  }

  func checkAccountFormat() {
    accountErrorText = account.isEmpty ? Localize.string("common_field_must_fill") : ""
  }

  func checkPasswordFormat() {
    passwordErrorText = password.isEmpty ? Localize.string("common_field_must_fill") : ""
  }

  func checkCaptchaFormat() {
    captchaErrorText = captchaText.isEmpty ? Localize.string("common_field_must_fill") : ""
  }

  func checkLoginInputFormat() {
    if
      account.count > 0,
      password.count > 5,
      countDownSecond == nil,
      captchaImage == nil ? true : captchaText.count > 0
    {
      disableLoginButton = false
    }
    else {
      disableLoginButton = true
    }
  }

  func login(callBack: @escaping (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void) {
    authUseCase.login(
      account: account,
      pwd: password,
      captcha: Captcha(passCode: captchaText))
      .do(onSubscribe: { [unowned self] in
        self.disableLoginButton = true
      })
      .flatMap { [unowned self] player in
        let setting = PlayerSetting(accountLocale: player.locale(), defaultProduct: player.defaultProduct)
        return self.navigationViewModel.initLoginNavigation(playerSetting: setting)
      }
      .trackOnDispose(loadingTracker)
      .observe(on: MainScheduler.instance)
      .subscribe(onSuccess: { [unowned self] navigation in
        self.loginOnSuccess()
        self.disableLoginButton = false
        callBack(navigation, nil)
      }, onFailure: { [unowned self] error in
        guard let loginFail = error as? LoginWarningException else {
          callBack(nil, error)
          return
        }
        self.disableLoginButton = false
        self.loginOnError(loginFail, callBack)
      })
      .disposed(by: self.disposeBag)
  }

  private func loginOnSuccess() {
    setRememberAccount()
    resetLoginLimit()
  }

  private func setRememberAccount() {
    localStorageRepo.setRememberAccount(isRememberMe ? account : nil)
  }

  private func resetLoginLimit() {
    localStorageRepo.setNeedCaptcha(nil)
    localStorageRepo.setLastOverLoginLimitDate(nil)
  }

  private func loginOnError(
    _ loginFail: LoginWarningException,
    _ callBack: @escaping (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void)
  {
    switch loginFail {
    case let error as LoginException.Failed1to5Exception:
      loginError = error
    case let error as LoginException.Failed6to10Exception:
      if captchaImage == nil {
        loginError = error
        getCaptchaImage()
      }
      else {
        loginError = error
      }
    case let error as LoginException.AboveVerifyLimitation:
      loginError = error
      let lastLoginLimitDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
      setLastOverLoginLimitDate(lastLoginLimitDate)
      launchLoginLimitTimer(lastLoginLimitDate)
    case is InvalidPlatformException:
      callBack(nil, loginFail)
    default:
      fatalError("Should not reach here.")
    }
  }

  func getCaptchaImage() {
    localStorageRepo.setNeedCaptcha(true)
    let _ = authUseCase.getCaptchaImage()
      .subscribe(onSuccess: { [weak self] image in
        self?.captchaImage = image
        self?.checkLoginInputFormat()
      })
  }

  private func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?) {
    localStorageRepo.setLastOverLoginLimitDate(lastOverLoginLimitDate)
  }

  private func launchLoginLimitTimer(_ limitDate: Date) {
    timerOverLoginLimit
      .start(timeInterval: 1, endTime: limitDate, block: { _, countDown, finish in
        self.countDownSecond = countDown
        if finish {
          self.countDownSecond = nil
        }

        self.checkLoginInputFormat()
      })
  }
  
  func getSupportLocale() -> SupportLocale {
    localStorageRepo.getSupportLocale()
  }
  
  func getCultureCode() -> String {
    localStorageRepo.getCultureCode()
  }
}
