import Foundation
import RxSwift
import SharedBu
import SwiftUI

class NewLoginViewModel: ObservableObject {
    @Published var account: String = ""
    @Published var password: String = ""
    @Published var isRememberMe: Bool = false
    @Published var captchaText: String = ""
    
    @Published private(set) var loginError: LoginException? = nil
    @Published private(set) var accountErrorText: String? = nil
    @Published private(set) var passwordErrorText: String? = nil
    @Published private(set) var captchaErrorText: String? = nil
    
    @Published private(set) var captchaImage: UIImage? = nil
    @Published private(set) var countDownSecond: Int? = nil
    @Published private(set) var disableLoginButton: Bool = true
    
    @Published private(set) var refreshCount: Int = 0
    
    private let authUseCase : AuthenticationUseCase
    private let configUseCase : ConfigurationUseCase
    private let navigationViewModel: NavigationViewModel
    private let localStorageRepo: LocalStorageRepositoryImpl
    private let timerOverLoginLimit : CountDownTimer = CountDownTimer()
    private let disposeBag = DisposeBag()
        
    init(_ authenticationUseCase : AuthenticationUseCase,
         _ configurationUseCase : ConfigurationUseCase,
         _ navigationViewModel: NavigationViewModel,
         _ localStorageRepo: LocalStorageRepositoryImpl) {
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
        if let lastOverLoginTimeLimit = lastOverLoginTimeLimit, lastOverLoginTimeLimit > Date() {
            launchLoginLimitTimer(lastOverLoginTimeLimit)
        }
    }
    
    func refreshUI() {
        refreshCount += 1
    }
    
    func getLoginErrorText() -> String? {
        guard let loginError = loginError else {
            return nil
        }
        
        switch loginError {
        case is LoginException.Failed1to5Exception:
            return Localize.string("login_invalid_username_password")
        case is LoginException.Failed6to10Exception:
            if captchaImage == nil {
                return Localize.string("login_invalid_username_password")
            } else {
                return Localize.string("login_invalid_username_password_captcha")
            }
        case is LoginException.AboveVerifyLimitation:
            return Localize.string("login_invalid_lockdown")
        default:
            fatalError("Should not reach here.")
        }
    }
    
    func checkAccountFormat() {
        accountErrorText = account.isEmpty ? Localize.string("common_field_must_fill") : nil
    }
    
    func checkPasswordFormat() {
        passwordErrorText = password.isEmpty ? Localize.string("common_field_must_fill") : nil
    }
    
    func checkCaptchaFormat() {
        captchaErrorText = captchaText.isEmpty ? Localize.string("common_field_must_fill") : nil
    }
    
    func checkLoginInputFormat() {
        if account.count > 0,
           password.count > 5,
           countDownSecond == nil,
           captchaImage == nil ? true : captchaText.count > 0
        {
            disableLoginButton = false
        } else {
            disableLoginButton = true
        }
    }
    
    func login(callBack: @escaping (NavigationViewModel.LobbyPageNavigation?, Error?) -> Void) {
        authUseCase.login(account: account, pwd: password, captcha: Captcha(passCode: captchaText))
            .do(onSubscribe: { [unowned self] in
                self.disableLoginButton = true
            })
            .flatMap({ [unowned self] (player) in
                let setting = PlayerSetting(accountLocale: player.locale(), defaultProduct: player.defaultProduct)
                return self.navigationViewModel.initLoginNavigation(playerSetting: setting)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [unowned self] (navigation: NavigationViewModel.LobbyPageNavigation) in
                self.loginOnSuccess()
                self.disableLoginButton = false
                callBack(navigation, nil)
            }, onError: { [unowned self] error in
                guard let loginFail = error as? LoginException else {
                    callBack(nil, error)
                    return
                }
                self.disableLoginButton = false
                self.loginOnError(loginFail)
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
    
    private func loginOnError(_ loginFail: LoginException) {
        switch loginFail {
        case is LoginException.Failed1to5Exception:
            loginError = loginFail
        case is LoginException.Failed6to10Exception:
            if captchaImage == nil {
                loginError = loginFail
                getCaptchaImage()
            } else {
                loginError = loginFail
            }
        case is LoginException.AboveVerifyLimitation:
            loginError = loginFail
            let lastLoginLimitDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
            setLastOverLoginLimitDate(lastLoginLimitDate)
            launchLoginLimitTimer(lastLoginLimitDate)
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
    
    private func setLastOverLoginLimitDate(_ lastOverLoginLimitDate : Date?) {
        localStorageRepo.setLastOverLoginLimitDate(lastOverLoginLimitDate)
    }
    
    private func launchLoginLimitTimer(_ limitDate: Date) {
        timerOverLoginLimit
            .start(timeInterval: 1, endTime: limitDate, block: {idx, countDown, finish in
                self.countDownSecond = countDown
                if finish {
                    self.countDownSecond = nil
                }
                
                self.checkLoginInputFormat()
            })
    }
}
