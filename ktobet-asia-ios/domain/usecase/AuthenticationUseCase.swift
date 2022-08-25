import Foundation
import SharedBu
import RxSwift

//Todo: Need refactor.
protocol AuthenticationUseCase {
    func login(account: String, pwd: String, captcha: Captcha) -> Single<Player>
    func logout() -> Completable
    func isLogged() -> Single<Bool>
    func getCaptchaImage() -> Single<UIImage>
    func getRememberAccount() -> String
    func getLastOverLoginLimitDate() -> Date
    func getNeedCaptcha() -> Bool
    func getUserName() -> String
    func setRememberAccount(_ rememberAccount: String?)
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?)
    func setNeedCaptcha(_ needCaptcha: Bool?)
    func setUserName(_ name: String)
    func accountValidation() -> Single<Bool>
}

class AuthenticationUseCaseImpl : AuthenticationUseCase {
    private let repoAuth : IAuthRepository
    private let repoPlayer : PlayerRepository
    private let repoLocalStorage : LocalStorageRepositoryImpl
    private let settingStore: SettingStore
    
    init(_ authRepository : IAuthRepository,
         _ playerRepository : PlayerRepository,
         _ localStorageRepo : LocalStorageRepositoryImpl,
         _ settingStore: SettingStore) {
        self.repoAuth = authRepository
        self.repoPlayer = playerRepository
        self.repoLocalStorage = localStorageRepo
        self.settingStore = settingStore
    }
    
    func login(account: String, pwd: String, captcha: Captcha) -> Single<Player> {
        repoAuth.authorize(account, pwd, captcha).flatMap { (data) -> Single<Player> in
            switch data.status {
            case .success: return self.repoPlayer.loadPlayer()
            case .failed1to5: return Single.error(LoginException.Failed1to5Exception.init(isLocked: data.isLocked))
            case .failed6to10: return Single.error(LoginException.Failed6to10Exception.init(isLocked: data.isLocked))
            case .failedabove11: return Single.error(LoginException.AboveVerifyLimitation.init(isLocked: data.isLocked))
            default: fatalError()
            }
        }
        .do(onSuccess: refreshHttpClient)
    }
    
    private func refreshHttpClient(_ player: Player) {
        repoPlayer.refreshHttpClient(playerLocale: player.locale())
        CustomServicePresenter.shared.changeCsDomainIfNeed()
    }
    
    func logout()->Completable  {
        return repoAuth.deAuthorize().do(onCompleted: { [weak self] in
            self?.settingStore.clearCache()
        })
    }
    
    func isLogged() -> Single<Bool>{
        return repoAuth.checkAuthorization()
    }
    
    func getCaptchaImage() -> Single<UIImage>{
        return repoAuth.getCaptchaImage()
    }
    
    func getRememberAccount() -> String{
        return repoLocalStorage.getRememberAccount()
    }
    
    func getNeedCaptcha() -> Bool{
        return repoLocalStorage.getNeedCaptcha()
    }
    
    func getLastOverLoginLimitDate() -> Date {
        return repoLocalStorage.getLastOverLoginLimitDate() ?? Date()
    }
    
    func getUserName() -> String {
        return repoLocalStorage.getUserName()
    }
    
    func setRememberAccount(_ rememberAccount : String?){
        repoLocalStorage.setRememberAccount(rememberAccount)
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
