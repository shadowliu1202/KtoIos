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
    
    enum LoginDataStatus {
        case valid
        case firstEmpty
        case empty
        case invalid
    }
    
    private var usecaseAuth : IAuthenticationUseCase!
    private var usecaseConfig : IConfigurationUseCase!
    private var accountEdited = false
    private var passwordEdited = false
    private var timerOverLoginLimit : KTOTimer = KTOTimer()
    
    var relayAccount = BehaviorRelay(value: "")
    var relayPassword = BehaviorRelay(value: "")
    var relayCaptcha = BehaviorRelay(value: "")
    var relayOverLoginLimit = BehaviorRelay(value: false)
    var relayCountDown = BehaviorRelay(value: 0)
    var relayImgCaptcha = BehaviorRelay<UIImage?>(value: nil)
    
    var lastLoginLimitDate : Date {
        set { usecaseAuth.setLastOverLoginLimitDate(newValue) }
        get { usecaseAuth.getLastOverLoginLimitDate() }
    }
    
    init(_ authenticationUseCase : IAuthenticationUseCase, _ configurationUseCase : IConfigurationUseCase) {
        usecaseAuth = authenticationUseCase
        usecaseConfig = configurationUseCase
        relayAccount.accept(usecaseAuth.getRemeberAccount())
        relayPassword.accept(usecaseAuth.getRememberPassword())
    }
    
    func continueLoginLimitTimer(){
        let count = Int(ceil(lastLoginLimitDate.timeIntervalSince1970 - Date().timeIntervalSince1970))
        if count > 0 {
            relayOverLoginLimit.accept(true)
            relayCountDown.accept(count)
            timerOverLoginLimit
                .countDown(timeInterval: 1, endTime: lastLoginLimitDate, block: {(idx, countDown, finish) in
                    self.relayCountDown.accept(countDown)
                    if finish {
                        self.relayOverLoginLimit.accept(false)
                    }
                })
        }
    }
    
    func launchLoginLimitTimer(){
        lastLoginLimitDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
        relayOverLoginLimit.accept(true)
        relayCountDown.accept(60)
        timerOverLoginLimit
            .countDown(timeInterval: 1, endTime: lastLoginLimitDate, block: {(idx, countDown, finish) in
                self.relayCountDown.accept(countDown)
                if finish {
                    self.relayOverLoginLimit.accept(false)
                }
            })
    }
    
    func stopLoginLimitTimer(){
        timerOverLoginLimit.stop()
    }
    
    func loginFrom(isRememberMe : Bool)->Single<(Player)>{
        let account = self.relayAccount.value
        let password = self.relayPassword.value
        let captcha = Captcha(passCode: self.relayCaptcha.value)
        return usecaseAuth
            .loginFrom(account: account, pwd: password, captcha: captcha)
            .map { (player) -> Player in
                if isRememberMe {
                    self.usecaseAuth.setRemeberAccount(self.relayAccount.value)
                    self.usecaseAuth.setRememberPassword(self.relayPassword.value)
                }
                self.usecaseAuth.setNeedCaptcha(nil)
                self.usecaseAuth.setLastOverLoginLimitDate(nil)
                return player
            }
    }
    
    func isRememberMe()->Bool{
        let haveAccount = usecaseAuth.getRemeberAccount().count > 0
        let havePassword = usecaseAuth.getRememberPassword().count > 0
        return haveAccount && havePassword
    }
    
    func getCaptchaImage()->Single<UIImage>{
        return usecaseAuth
            .getCaptchaImage()
            .map { (img) -> UIImage in
                self.usecaseAuth.setNeedCaptcha(true)
                self.relayImgCaptcha.accept(img)
                return img
            }
    }
    
    func event()-> (accountValid : Observable<LoginDataStatus>,
                    passwordValid : Observable<LoginDataStatus>,
                    captchaImage : Observable<UIImage?>,
                    dataValid : Observable<Bool>,
                    countDown : Observable<Int>){
        
        let accountValid = relayAccount
            .map { (text) -> LoginDataStatus in
                if text.count > 0{ self.accountEdited = true }
                if text.count > 0 { return .valid }
                else { return self.accountEdited ? .empty : .firstEmpty }
            }
        
        let passwordValid = relayPassword.map { (text) -> LoginDataStatus in
            if text.count > 0{ self.passwordEdited = true }
            if text.count >= 6{ return .valid }
            else if text.count == 0 { return self.passwordEdited ? .empty : .firstEmpty }
            else { return .invalid }
        }
        
        let image : Observable<UIImage?> = {
            if usecaseAuth.getNeedCaptcha(){
                return getCaptchaImage()
                    .asObservable()
                    .flatMap { (image) -> Observable<UIImage?> in
                        self.relayImgCaptcha.accept(image)
                        return self.relayImgCaptcha.asObservable()
                    }
            } else {
                return self.relayImgCaptcha.asObservable()
            }
        }()
        
        let limit = relayOverLoginLimit.asObservable()
        let dataValid = Observable.combineLatest(accountValid, passwordValid, limit){
            return $0 == LoginDataStatus.valid && $1 == LoginDataStatus.valid && !$2
        }
        return (accountValid: accountValid,
                passwordValid: passwordValid,
                captchaImage: image,
                dataValid: dataValid,
                countDown: relayCountDown.asObservable())
    }
}
