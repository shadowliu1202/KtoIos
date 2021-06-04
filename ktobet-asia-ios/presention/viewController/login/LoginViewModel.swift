//
//  LoginViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/4.
//

import Foundation
import RxSwift
import SharedBu
import RxCocoa

class LoginViewModel{
    
    enum LoginDataStatus {
        case valid
        case firstEmpty
        case empty
        case invalid
    }
    
    private var usecaseAuth : AuthenticationUseCase!
    private var usecaseConfig : ConfigurationUseCase!
    private var accountEdited = false
    private var passwordEdited = false
    private var timerOverLoginLimit : KTOTimer = KTOTimer()
    
    var relayAccount = BehaviorRelay(value: "")
    var relayPassword = BehaviorRelay(value: "")
    var relayCaptcha = BehaviorRelay(value: "")
    var relayOverLoginLimit = BehaviorRelay(value: false)
    var relayCountDown = BehaviorRelay(value: 0)
    var relayImgCaptcha = BehaviorRelay<UIImage?>(value: nil)
        
    init(_ authenticationUseCase : AuthenticationUseCase, _ configurationUseCase : ConfigurationUseCase) {
        usecaseAuth = authenticationUseCase
        usecaseConfig = configurationUseCase
        relayAccount.accept(usecaseAuth.getRemeberAccount())
    }
    
    func refresh(){
        relayAccount.accept(relayAccount.value)
        relayPassword.accept(relayPassword.value)
        relayCaptcha.accept(relayCaptcha.value)
        relayOverLoginLimit.accept(relayOverLoginLimit.value)
        relayCountDown.accept(relayCountDown.value)
        relayImgCaptcha.accept(relayImgCaptcha.value)
    }
    
    func continueLoginLimitTimer(){
        var lastLoginLimitDate = usecaseAuth.getLastOverLoginLimitDate()
        let count = Int(ceil(lastLoginLimitDate.timeIntervalSince1970 - Date().timeIntervalSince1970))
        if count <= 0 {
            let date = Date()
            usecaseAuth.setLastOverLoginLimitDate(date)
            lastLoginLimitDate = date
        }
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
    
    func launchLoginLimitTimer(){
        let lastLoginLimitDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
        usecaseAuth.setLastOverLoginLimitDate(lastLoginLimitDate)
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
                self.usecaseAuth.setRemeberAccount(isRememberMe ? self.relayAccount.value : nil)
                self.usecaseAuth.setNeedCaptcha(nil)
                self.usecaseAuth.setLastOverLoginLimitDate(nil)
                self.usecaseAuth.setUserName(player.playerInfo.withdrawalName)
                return player
            }
    }
    
    func isRememberMe()->Bool{
        let haveAccount = usecaseAuth.getRemeberAccount().count > 0
        return haveAccount
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
                    captchaValid : Observable<Bool>,
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
        let captchaValid = relayImgCaptcha
            .asObservable()
            .flatMapLatest { (captchaImg) -> Observable<Bool> in
                return self.relayCaptcha
                    .asObservable()
                    .map { (captcha) -> Bool in
                        guard captchaImg != nil else {
                            return true
                        }
                        return captcha.count > 0
                    }
            }
        let dataValid = Observable.combineLatest(accountValid, passwordValid, limit, captchaValid){
            return $0 == LoginDataStatus.valid && $1 == LoginDataStatus.valid && !$2 && $3
        }
        return (accountValid: accountValid,
                passwordValid: passwordValid,
                captchaValid: captchaValid,
                captchaImage: image,
                dataValid: dataValid,
                countDown: relayCountDown.asObservable())
    }
}
