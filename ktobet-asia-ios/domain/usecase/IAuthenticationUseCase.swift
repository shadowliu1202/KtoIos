//
//  IAuthenticationUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/4.
//

import Foundation
import share_bu
import RxSwift

protocol IAuthenticationUseCase {
    func loginFrom(account: String, pwd: String, captcha: Captcha)->Single<Player>
    func logout()->Completable
    func isLogged()->Single<Bool>
    func getCaptchaImage()->Single<UIImage>
    func getRemeberAccount()->String
    func getRememberPassword()->String
    func getLastOverLoginLimitDate()->Date
    func getNeedCaptcha()->Bool
    func setRemeberAccount(_ rememberAccount : String?)
    func setRememberPassword(_ rememberPassword : String?)
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate : Date?)
    func setNeedCaptcha(_ needCaptcha : Bool?)
}

class IAuthenticationUseCaseImpl : IAuthenticationUseCase {
    
    private var repoAuth : IAuthRepository!
    private var repoPlayer : PlayerRepository!
    private var repoLocalStorage : LocalStorageRepository!
    
    init(_ authRepository : IAuthRepository,
         _ playerRepository : PlayerRepository,
         _ localStroageRepo : LocalStorageRepository) {
        self.repoAuth = authRepository
        self.repoPlayer = playerRepository
        self.repoLocalStorage = localStroageRepo
    }
    
    func loginFrom(account: String, pwd: String, captcha: Captcha)->Single<Player>{
        let login = repoAuth.authorize(account, pwd, captcha)
        return login.flatMap { (stat) -> Single<Player> in
            switch stat.status {
            case .success: return self.repoPlayer.loadPlayer()
            default:
                let error = LoginError()
                error.status = stat.status
                error.isLock = stat.isLocked
                return Single.error(error)
            }
        }
    }
    
    func logout()->Completable  {
        return repoAuth.deAuthorize()
    }
    
    func isLogged()->Single<Bool>{
        return repoAuth.checkAuthorization()
    }
    
    func getCaptchaImage()->Single<UIImage>{
        return repoAuth.getCaptchaImage()
    }
    
    func getRemeberAccount()->String{
        return repoLocalStorage.getRemeberAccount()
    }
    
    func getRememberPassword()->String{
        return repoLocalStorage.getRememberPassword()
    }
    
    func getNeedCaptcha()->Bool{
        return repoLocalStorage.getNeedCaptcha()
    }
    
    func getLastOverLoginLimitDate()->Date{
        return repoLocalStorage.getLastOverLoginLimitDate()
    }
    
    func setRemeberAccount(_ rememberAccount : String?){
        repoLocalStorage.setRemeberAccount(rememberAccount)
    }
    
    func setRememberPassword(_ rememberPassword : String?){
        repoLocalStorage.setRememberPassword(rememberPassword)
    }
    
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate : Date?){
        repoLocalStorage.setLastOverLoginLimitDate(lastOverLoginLimitDate)
    }
    
    func setNeedCaptcha(_ needCaptcha : Bool?){
        repoLocalStorage.setNeedCaptcha(needCaptcha)
    }
}
