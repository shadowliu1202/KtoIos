import Foundation
import SharedBu
import RxSwift

protocol AuthenticationUseCase {
    func loginFrom(account: String, pwd: String, captcha: Captcha)->Single<Player>
    func logout()->Completable
    func isLogged()->Single<Bool>
    func getCaptchaImage()->Single<UIImage>
    func getRemeberAccount()->String
    func getLastOverLoginLimitDate()->Date
    func getNeedCaptcha()->Bool
    func getUserName() -> String
    func setRemeberAccount(_ rememberAccount : String?)
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate : Date?)
    func setNeedCaptcha(_ needCaptcha : Bool?)
    func setUserName(_ name: String)
    func accountValidation() -> Single<Bool>
}

class AuthenticationUseCaseImpl : AuthenticationUseCase {
    
    private var repoAuth : IAuthRepository!
    private var repoPlayer : PlayerRepository!
    private var repoLocalStorage : LocalStorageRepository!
    private var settingStore: SettingStore!
    
    init(_ authRepository : IAuthRepository,
         _ playerRepository : PlayerRepository,
         _ localStroageRepo : LocalStorageRepository,
         _ settingStore: SettingStore) {
        self.repoAuth = authRepository
        self.repoPlayer = playerRepository
        self.repoLocalStorage = localStroageRepo
        self.settingStore = settingStore
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
        return repoAuth.deAuthorize().do(onCompleted: { [weak self] in
            self?.settingStore.clearCache()
        })
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
    
    func getNeedCaptcha()->Bool{
        return repoLocalStorage.getNeedCaptcha()
    }
    
    func getLastOverLoginLimitDate()->Date{
        return repoLocalStorage.getLastOverLoginLimitDate()
    }
    
    func getUserName() -> String {
        return repoLocalStorage.getUserName()
    }
    
    func setRemeberAccount(_ rememberAccount : String?){
        repoLocalStorage.setRemeberAccount(rememberAccount)
    }
    
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate : Date?){
        repoLocalStorage.setLastOverLoginLimitDate(lastOverLoginLimitDate)
    }
    
    func setNeedCaptcha(_ needCaptcha : Bool?){
        repoLocalStorage.setNeedCaptcha(needCaptcha)
    }
    
    func setUserName(_ name: String) {
        repoLocalStorage.setUserName(name)
    }
    
    func accountValidation() -> Single<Bool> {
        return Single.zip(repoAuth.checkAuthorization(), repoPlayer.hasPlayerData()).map({ (isAuth, hasPlayerData) in
            return isAuth && hasPlayerData
        })
    }
}
