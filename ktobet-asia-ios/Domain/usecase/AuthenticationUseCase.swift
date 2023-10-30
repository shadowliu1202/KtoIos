import Foundation
import RxSwift
import sharedbu

// TODO: Need refactor.
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

class AuthenticationUseCaseImpl: AuthenticationUseCase {
  private let repoAuth: IAuthRepository
  private let repoPlayer: PlayerRepository
  private let localStorageRepo: LocalStorageRepository
  private let settingStore: SettingStore

  @Injected(name: "CheckingIsLogged") private var checkIsLoggedTracker: ActivityIndicator

  init(
    authRepository: IAuthRepository,
    playerRepository: PlayerRepository,
    localStorageRepo: LocalStorageRepository,
    settingStore: SettingStore)
  {
    self.repoAuth = authRepository
    self.repoPlayer = playerRepository
    self.localStorageRepo = localStorageRepo
    self.settingStore = settingStore
  }

  func login(account: String, pwd: String, captcha: Captcha) -> Single<Player> {
    repoAuth.authorize(account, pwd, captcha)
      .flatMap { data -> Single<Player> in
        switch data.status {
        case .success: return self.repoPlayer.loadPlayer()
        case .failed1to5: return Single.error(LoginException.Failed1to5Exception(isLocked: data.isLocked))
        case .failed6to10: return Single.error(LoginException.Failed6to10Exception(isLocked: data.isLocked))
        case .failedabove11: return Single.error(LoginException.AboveVerifyLimitation(isLocked: data.isLocked))
        default: fatalError()
        }
      }
      .do(onSuccess: { [weak self, localStorageRepo] in
        self?.refreshHttpClient($0)
        self?.logLoginDay()
      })
  }

  private func refreshHttpClient(_ player: Player) {
    repoPlayer.refreshHttpClient(playerLocale: player.locale())
    CustomServicePresenter.shared.changeCsDomainIfNeed()
  }

  private func logLoginDay() {
    let now = Date().convertdateToUTC()
    let lastDay = localStorageRepo.getLastLoginDate()?.convertdateToUTC()
    if lastDay?.betweenTwoDay(sencondDate: now) != 0 {
      AnalyticsLog.shared.playerLogin()
      localStorageRepo.setLastLoginDate(now)
    }
  }

  func logout() -> Completable {
    .create { [weak self] completable -> Disposable in
      self?.repoAuth.deAuthorize()
      self?.settingStore.clearCache()
      FirebaseLog.shared.clearUserID()
      self?.localStorageRepo.setPlayerInfo(nil)
      self?.localStorageRepo.setLastAPISuccessDate(nil)
      
      completable(.completed)

      return Disposables.create { }
    }
  }

  func isLastAPISuccessDateExpire() -> Bool {
    guard let lastAPISuccessDate = localStorageRepo.getLastAPISuccessDate() else { return true }
    return lastAPISuccessDate.addingTimeInterval(1800) < Date()
  }

  func isLogged() -> Single<Bool> {
    repoAuth
      .checkAuthorization()
      .trackOnDispose(checkIsLoggedTracker)
  }

  func getCaptchaImage() -> Single<UIImage> {
    repoAuth.getCaptchaImage()
  }

  func getRememberAccount() -> String {
    localStorageRepo.getRememberAccount()
  }

  func getNeedCaptcha() -> Bool {
    localStorageRepo.getNeedCaptcha()
  }

  func getLastOverLoginLimitDate() -> Date {
    localStorageRepo.getLastOverLoginLimitDate() ?? Date()
  }

  func getUserName() -> String {
    localStorageRepo.getUserName()
  }

  func setRememberAccount(_ rememberAccount: String?) {
    localStorageRepo.setRememberAccount(rememberAccount)
  }

  func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?) {
    localStorageRepo.setLastOverLoginLimitDate(lastOverLoginLimitDate)
  }

  func setNeedCaptcha(_ needCaptcha: Bool?) {
    localStorageRepo.setNeedCaptcha(needCaptcha)
  }

  func setUserName(_ name: String) {
    localStorageRepo.setUserName(name)
  }

  func accountValidation() -> Single<Bool> {
    Single.zip(repoAuth.checkAuthorization(), repoPlayer.hasPlayerData()).map({ isAuth, hasPlayerData in
      isAuth && hasPlayerData
    })
  }
}
