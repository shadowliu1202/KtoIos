import Foundation
import RxCocoa
import RxSwift
import sharedbu

class SignupEmailViewModel {
  enum RegistrationVerification {
    case valid
    case invalid
  }

  private var registerUseCase: RegisterUseCase!
  private var configurationUseCase: ConfigurationUseCase!
  private var authenticationUseCase: AuthenticationUseCase!

  // MARK: INITIALIZE
  init(
    _ registerUseCase: RegisterUseCase,
    _ configurationUseCase: ConfigurationUseCase,
    _ authenticationUseCase: AuthenticationUseCase)
  {
    self.registerUseCase = registerUseCase
    self.configurationUseCase = configurationUseCase
    self.authenticationUseCase = authenticationUseCase
  }

  func verifyTimer() -> Observable<Int> {
    let first = Observable<Int>.just(0)
    let second = Observable<Int>.interval(RxTimeInterval.seconds(5), scheduler: MainScheduler.instance)
    return Observable
      .of(first, second)
      .merge()
  }

  // MARK: API
  func checkRegistration(_ account: String, _ password: String) -> Single<RegistrationVerification> {
    registerUseCase
      .checkAccountVerification(account)
      .flatMap { [unowned self] success -> Single<RegistrationVerification> in
        if success {
          return self.authenticationUseCase
            .login(account: account, pwd: password, captcha: Captcha(passCode: ""))
            .map { _ -> RegistrationVerification in
              .valid
            }
        }
        else {
          return Single.just(.invalid)
        }
      }
  }

  func resendOtp() -> Completable {
    registerUseCase.resendRegisterOtp()
  }
}
