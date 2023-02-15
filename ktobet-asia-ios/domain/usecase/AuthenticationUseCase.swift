import Foundation
import SharedBu
import RxSwift

//Todo: Need refactor.
protocol AuthenticationUseCase {
    func isLastAPISuccessDateExpire() -> Bool
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
    private let repoLocalStorage : LocalStorageRepository
    private let settingStore: SettingStore
  
    @Injected(name: "CheckingIsLogged") private var checkIsLoggedTracker: ActivityIndicator
  
    init(
      authRepository : IAuthRepository,
      playerRepository : PlayerRepository,
      localStorageRepo : LocalStorageRepository,
      settingStore: SettingStore
    ) {
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
        .do(onSuccess: logLoginDay)
    }
    
    private func refreshHttpClient(_ player: Player) {
        repoPlayer.refreshHttpClient(playerLocale: player.locale())
        CustomServicePresenter.shared.changeCsDomainIfNeed()
    }
    
    private func logLoginDay(_ : Player) {
        let now = Date().convertdateToUTC()
        let lastDay = repoLocalStorage.getLastLoginDate()?.convertdateToUTC()
        if lastDay?.betweenTwoDay(sencondDate: now) != 0 {
            AnalyticsLog.shared.playerLogin()
            repoLocalStorage.setLastLoginDate(now)
        }
    }
    
    func logout() -> Completable  {
        return repoAuth.deAuthorize()
            .do(onCompleted: { [weak self] in
                self?.settingStore.clearCache()
                FirebaseLog.shared.clearUserID()
                self?.repoLocalStorage.setPlayerInfo(nil)
                self?.repoLocalStorage.setLastAPISuccessDate(nil)
                Logger.shared.debug("clear player info.")
            })
    }
    
    func isLastAPISuccessDateExpire() -> Bool {
        guard let lastAPISuccessDate = repoLocalStorage.getLastAPISuccessDate() else { return true }
        return lastAPISuccessDate.addingTimeInterval(1800) < Date()
    }
    
    func isLogged() -> Single<Bool> {
      repoAuth
        .checkAuthorization()
        .trackActivity(checkIsLoggedTracker)
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
