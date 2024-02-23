import Foundation
import RxSwift
import sharedbu
import SwiftyJSON

protocol IAuthRepository {
  func register(_ account: UserAccount, _ password: UserPassword, _ locale: SupportLocale) -> Completable
  func authorize(_ otp: String) -> Single<String>
  func authorize(_ account: String, _ password: String, _ captcha: Captcha) -> Single<LoginStatus>
  func deAuthorize()
  func checkAuthorization() -> Single<Bool>
  func resendRegisterOtp() -> Completable
  func checkRegistration(_ account: String) -> Single<Bool>
  func getCaptchaImage() -> Single<UIImage>
}

protocol ResetPasswordRepository {
  func requestResetPassword(_ account: Account) -> Completable
  func requestResetOtp(_ otp: String) -> Single<Bool>
  func requestResendOtp() -> Completable
  func resetPassword(password: String) -> Completable
}

class IAuthRepositoryImpl: IAuthRepository {
  private let api: AuthenticationApi
  private let httpClient: HttpClient
  private let cookieManager: CookieManager
  
  init(_ api: AuthenticationApi, _ httpClient: HttpClient, _ cookieManager: CookieManager) {
    self.api = api
    self.httpClient = httpClient
    self.cookieManager = cookieManager
  }

  func register(_ account: UserAccount, _ password: UserPassword, _ locale: SupportLocale) -> Completable {
    let accountType: Int = {
      if account.type.self is Account.Email { return 1 }
      else if account.type.self is Account.Phone { return 2 }
      else { return 0 }
    }()
    let currencyCode: String = {
      if locale.self is SupportLocale.China { return "1" }
      else if locale.self is SupportLocale.Vietnam { return "2" }
      else { return "0" }
    }()
    let request = IRegisterRequest(
      account: account.type.identity,
      accountType: accountType,
      currencyCode: currencyCode,
      password: password.value,
      realName: account.username)
    return api.register(request)
  }

  func authorize(_ otp: String) -> Single<String> {
    let para = IVerifyOtpRequest(verifyCode: otp)
    return api.verifyOtp(para).map { response -> String in
      response.data ?? ""
    }
  }

  func authorize(_ account: String, _ password: String, _ captcha: Captcha) -> Single<LoginStatus> {
    api.login(account, password, captcha)
      .do(onSubscribe: { Logger.shared.info("Login_onSubscribe") })
      .map { response -> LoginStatus in
        let tryStatus: LoginStatus.TryStatus = {
          switch response.data?.phase {
          case 0: return LoginStatus.TryStatus.success
          case 1: return LoginStatus.TryStatus.failed1to5
          case 2: return LoginStatus.TryStatus.failed6to10
          case 3: return LoginStatus.TryStatus.failedAbove11
          default: return LoginStatus.TryStatus.failedAbove11
          }
        }()
        let isLocked = response.data?.isLocked ?? false
        let isPlatformValid = response.data?.platformIsAvailable ?? false
      
        if tryStatus == .success {
          Logger.shared.info("Player_login")
        }
      
        return LoginStatus(status: tryStatus, isLocked: isLocked, isPlatformValid: isPlatformValid)
      }
  }

  func deAuthorize() {
    cookieManager.removeAllCookies()
  }

  func checkAuthorization() -> Single<Bool> {
    api.isLogged().map { response -> Bool in
      response.data ?? false
    }
  }

  func resendRegisterOtp() -> Completable {
    api.resendRegisterOtp()
  }

  func checkRegistration(_ account: String) -> Single<Bool> {
    api.checkAccount(account).map { response -> Bool in
      response.data == "true" ? true : false
    }
  }

  func getCaptchaImage() -> Single<UIImage> {
    api.getCaptchaImage()
  }
}

extension IAuthRepositoryImpl: ResetPasswordRepository {
  func requestResetOtp(_ otp: String) -> Single<Bool> {
    let para = IVerifyOtpRequest(verifyCode: otp)
    return api.verifyResetOtp(para).map { response -> Bool in
      response.data ?? false
    }
  }

  func requestResetPassword(_ account: Account) -> Completable {
    api.requestResetPassword(
      account.identity,
      accountType: account is Account.Phone ? AccountType.phone.rawValue : AccountType.email.rawValue)
  }

  func requestResendOtp() -> Completable {
    api.resentOtp()
  }

  func resetPassword(password: String) -> Completable {
    api.changePassword(INewPasswordRequest(newPassword: password))
  }
}
