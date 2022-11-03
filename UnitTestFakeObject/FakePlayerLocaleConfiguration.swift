import SharedBu
@testable import ktobet_asia_ios_qat

class FakePlayerLocaleConfiguration: PlayerConfiguration,
                                     LocalStorageRepository {
    
    let stubSupportLocale: SupportLocale
    
    required init(_ ignoreThis: String?) {
        stubSupportLocale = .China()
    }
    
    init(stubSupportLocale: SupportLocale) {
        self.stubSupportLocale = stubSupportLocale
    }
    
    func getCultureCode() -> String {
        return ""
    }
    
    func getSupportLocale() -> SupportLocale {
        return stubSupportLocale
    }
    
    func getPlayerInfo() -> ktobet_asia_ios_qat.PlayerInfoCache? { nil }
    
    func getLastAPISuccessDate() -> Date? { nil }
    
    func getRememberMe() -> Bool { false }
    
    func getRememberAccount() -> String { "" }
    
    func getRememberPassword() -> String { "" }
    
    func getLastOverLoginLimitDate() -> Date? { nil }
    
    func getNeedCaptcha() -> Bool { false }
    
    func getRetryCount() -> Int { 0 }
    
    func getOtpRetryCount() -> Int { 0 }
    
    func getCountDownEndTime() -> Date? { nil }
    
    func getBalanceHiddenState(gameId: String) -> Bool { false }
    
    func getUserName() -> String { "" }
    
    func getLocalCurrency() -> AccountCurrency { .zero() }
    
    func getLocale() -> Locale { .current }
    
    func setRememberMe(_ rememberMe: Bool?) { }
    
    func setRememberAccount(_ rememberAccount: String?) { }
    
    func setRememberPassword(_ rememberPassword: String?) { }
    
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?) { }
    
    func setNeedCaptcha(_ needCaptcha: Bool?) { }
    
    func setRetryCount(_ count: Int) { }
    
    func setOtpRetryCount(_ count: Int) { }
    
    func setCountDownEndTime(date: Date?) { }
    
    func setBalanceHiddenState(isHidden: Bool, gameId: String) { }
    
    func setUserName(_ name: String) { }
    
    func setCultureCode(_ cultureCode: String) { }
    
    func setPlayerInfo(_ playerInfo: ktobet_asia_ios_qat.PlayerInfoCache?) { }
    
    func setLastAPISuccessDate(_ time: Date?) { }
}
