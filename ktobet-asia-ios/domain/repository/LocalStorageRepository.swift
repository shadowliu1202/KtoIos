import Foundation
import SharedBu

protocol LocalStorageRepository {
    func getRememberMe() -> Bool
    func getRememberAccount() -> String
    func getRememberPassword() -> String
    func getLastOverLoginLimitDate() -> Date?
    func getNeedCaptcha() -> Bool
    func getRetryCount() -> Int
    func getOtpRetryCount() -> Int
    func getCountDownEndTime() -> Date?
    func getBalanceHiddenState(gameId: String) -> Bool
    func getUserName() -> String
    func getLocalCurrency() -> AccountCurrency
    func getLocale() -> Locale
    func getCultureCode() -> String
    func getSupportLocale() -> SupportLocale
    
    func getPlayerInfo() -> PlayerInfoCache?
    func getLastAPISuccessDate() -> Date?
    
    func setRememberMe(_ rememberMe: Bool?)
    func setRememberAccount(_ rememberAccount: String?)
    func setRememberPassword(_ rememberPassword: String?)
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?)
    func setNeedCaptcha(_ needCaptcha: Bool?)
    func setRetryCount(_ count: Int)
    func setOtpRetryCount(_ count: Int)
    func setCountDownEndTime(date: Date?)
    func setBalanceHiddenState(isHidden: Bool, gameId: String)
    func setUserName(_ name: String)
    func setCultureCode(_ cultureCode: String)
    func setPlayerInfo(_ playerInfo: PlayerInfoCache?)
    func setLastAPISuccessDate(_ time: Date?)
    
    func timezone() -> SharedBu.TimeZone
    func localeTimeZone() -> Foundation.TimeZone
}

class LocalStorageRepositoryImpl: LocalStorageRepository,
                                  LocalStorable {
    let playerConfiguration: PlayerConfiguration
    
    init(playerConfiguration: PlayerConfiguration) {
        self.playerConfiguration = playerConfiguration
        
        guard let _: String = get(key: .cultureCode)
        else {
            initCultureCode()
            return
        }
    }
    
    private func initCultureCode() {
        let localeCultureCode = systemLocaleToCultureCode()
        setCultureCode(localeCultureCode)
        Theme.shared.changeEntireAPPFont(by: getSupportLocale())
    }
    
    private func systemLocaleToCultureCode() -> String {
        switch Locale.current.languageCode {
        case "vi":
            return SupportLocale.Vietnam.shared.cultureCode()
        case "zh":
            fallthrough
        default:
            return SupportLocale.China.shared.cultureCode()
        }
    }
    
    func getRememberMe() -> Bool {
        get(key: .rememberMe) ?? false
    }

    func getRememberAccount() -> String {
        get(key: .rememberAccount) ?? ""
    }

    func getRememberPassword() -> String {
        get(key: .rememberPassword) ?? ""
    }

    func getLastOverLoginLimitDate() -> Date? {
        get(key: .lastOverLoginLimitDate)
    }

    func getNeedCaptcha() -> Bool {
        get(key: .needCaptcha) ?? false
    }

    func getRetryCount() -> Int {
        get(key: .retryCount) ?? 0
    }

    func getOtpRetryCount() -> Int {
        get(key: .otpRetryCount) ?? 0
    }

    func getCountDownEndTime() -> Date? {
        get(key: .countDownEndTime)
    }

    func getBalanceHiddenState(gameId: String) -> Bool {
        get(key: .balanceHiddenState(gameId: gameId)) ?? false
    }

    func getUserName() -> String {
        get(key: .userName) ?? ""
    }
    
    func getLocalCurrency() -> AccountCurrency {
        return FiatFactory.init().create(supportLocale: getSupportLocale(), amount_: "0")
    }
    
    func getLocale() -> Locale {
        return Locale(identifier: getCultureCode())
    }
    
    func getCultureCode() -> String {
        get(key: .cultureCode) ?? ""
    }
    
    func getSupportLocale() -> SupportLocale {
        playerConfiguration.supportLocale
    }
    
    func getPlayerInfo() -> PlayerInfoCache? {
        do {
            return try getObject(key: .playerInfoCache, to: PlayerInfoCache.self)
        } catch {
            return nil
        }
    }
    
    func getLastAPISuccessDate() -> Date? {
        get(key: .lastAPISuccessDate)
    }

    func setRememberMe(_ rememberMe: Bool?) {
        set(value: rememberMe, key: .rememberMe)
    }

    func setRememberAccount(_ rememberAccount: String?) {
        set(value: rememberAccount, key: .rememberAccount)
    }

    func setRememberPassword(_ rememberPassword: String?) {
        set(value: rememberPassword, key: .rememberPassword)
    }

    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?) {
        set(value: lastOverLoginLimitDate, key: .lastOverLoginLimitDate)
    }

    func setNeedCaptcha(_ needCaptcha: Bool?) {
        set(value: needCaptcha, key: .needCaptcha)
    }

    func setRetryCount(_ count: Int) {
        set(value: count, key: .retryCount)
    }

    func setOtpRetryCount(_ count: Int) {
        set(value: count, key: .otpRetryCount)
    }

    func setCountDownEndTime(date: Date?) {
        set(value: date, key: .countDownEndTime)
    }

    func setBalanceHiddenState(isHidden: Bool, gameId: String) {
        set(value: isHidden, key: .balanceHiddenState(gameId: gameId))
    }

    func setUserName(_ name: String) {
        set(value: name, key: .userName)
    }
    
    func setCultureCode(_ cultureCode: String) {
        set(value: cultureCode, key: .cultureCode)
    }
    
    func setPlayerInfo(_ playerInfo: PlayerInfoCache?) {
        do {
            try setObject(playerInfo, for: .playerInfoCache)
        } catch {
            Logger.shared.error(error)
        }
    }
    
    func setLastAPISuccessDate(_ time: Date?) {
        set(value: time, key: .lastAPISuccessDate)
    }
    
    func timezone() -> SharedBu.TimeZone {
        playerConfiguration.timezone()
    }
    
    func localeTimeZone() -> Foundation.TimeZone {
        playerConfiguration.localeTimeZone()
    }
}
