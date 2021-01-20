//
//  LoginViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/4.
//

import Foundation
import RxSwift
import share_bu
import RxCocoa

class LoginViewModel{
    
    let kRememberAccount = "rememberAccount"
    let kRememberPassword = "rememberPassword"
    let kLastCaptchaImage = "lastCaptchaImage"
    let kLastOverLoginLimitDate = "overLoginLimit"
    
    enum LoginDataStatus {
        case valid
        case firstEmpty
        case empty
        case invalid
    }
    
    var rememberAccount : String {
        get{ return UserDefaults.standard.string(forKey: kRememberAccount) ?? "" }
        set{
            UserDefaults.standard.setValue(newValue, forKey: kRememberAccount)
            UserDefaults.standard.synchronize()
        }
    }
    var rememberPassword : String {
        get { return UserDefaults.standard.string(forKey: kRememberPassword) ?? ""}
        set {
            UserDefaults.standard.setValue(newValue, forKey: kRememberPassword)
            UserDefaults.standard.synchronize()
        }
    }
    var lastOverLoginLimitDate : Date? {
        get { return UserDefaults.standard.object(forKey: kLastOverLoginLimitDate) as? Date}
        set {
            UserDefaults.standard.setValue(newValue, forKey: kLastOverLoginLimitDate)
            UserDefaults.standard.synchronize()
        }
    }
    var lastCaptchaImage : UIImage? {
        get {
            guard let url = UserDefaults.standard.url(forKey: kLastCaptchaImage),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }
        set {
            if let data = newValue?.pngData(){
                let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let url = documents.appendingPathComponent("captcha.png")
                do {
                    try data.write(to: url)
                    UserDefaults.standard.set(url, forKey: kLastCaptchaImage)
                    UserDefaults.standard.synchronize()
                } catch{
                    print("write captcha fail")
                }
            }
        }
    }
    
    private var authenticationUseCase : IAuthenticationUseCase!
    private var configurationUseCase : IConfigurationUseCase!
    private var accountEdited = false
    private var passwordEdited = false
    
    var relayAccount = BehaviorRelay(value: "")
    var relayPassword = BehaviorRelay(value: "")
    var relayCaptcha = BehaviorRelay(value: "")
    var relayOverLoginLimit = BehaviorRelay(value: false)
    var relayImgCaptcha = BehaviorRelay<UIImage?>(value: nil)
    
    init(_ authenticationUseCase : IAuthenticationUseCase, _ configurationUseCase : IConfigurationUseCase) {
        self.authenticationUseCase = authenticationUseCase
        self.configurationUseCase = configurationUseCase
        self.relayAccount.accept(rememberAccount)
        self.relayPassword.accept(rememberPassword)
        self.relayImgCaptcha.accept(lastCaptchaImage)
    }
    
    func overLoginLimit(isOver:Bool){
        relayOverLoginLimit.accept(isOver)
    }
    
    func newCaptchaImage(image : UIImage){
        self.lastCaptchaImage = image
        self.relayImgCaptcha.accept(image)
    }
    
    func loginFrom()->Single<(player:Player, account: String, password: String)>{
        let account = self.relayAccount.value
        let password = self.relayPassword.value
        let captcha = Captcha(passCode: self.relayCaptcha.value)
        return authenticationUseCase
            .loginFrom(account: account, pwd: password, captcha: captcha)
            .map { (player) -> (Player, String, String) in
                return (player, self.relayAccount.value, self.relayPassword.value)
            }
    }
    
    func getCaptchaImage()->Single<UIImage>{
        return authenticationUseCase.getCaptchaImage()
    }
    
    func event()-> (accountValid : Observable<LoginDataStatus>,
                    passwordValid : Observable<LoginDataStatus>,
                    captchaImage : Observable<UIImage?>,
                    dataValid : Observable<Bool>){
        
        let accountValid = relayAccount
            .map { (text) -> LoginDataStatus in
                if text.count > 0{
                    self.accountEdited = true
                }
                if text.count > 0 {
                    return .valid
                } else{
                    return self.accountEdited ? .empty : .firstEmpty
                }
            }
        
        let passwordValid = relayPassword.map { (text) -> LoginDataStatus in
            if text.count > 0{
                self.passwordEdited = true
            }
            if text.count >= 6{
                return .valid
            } else if text.count == 0 {
                return self.passwordEdited ? .empty : .firstEmpty
            } else {
                return .invalid
            }
        }
        
        let limit = relayOverLoginLimit.asObservable()
        let dataValid = Observable.combineLatest(accountValid, passwordValid, limit){
            return $0 == LoginDataStatus.valid && $1 == LoginDataStatus.valid && !$2
        }
        return (accountValid: accountValid,
                passwordValid: passwordValid,
                captchaImage: relayImgCaptcha.asObservable(),
                dataValid: dataValid)
    }
}
