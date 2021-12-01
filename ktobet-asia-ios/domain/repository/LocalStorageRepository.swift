import Foundation
import SharedBu

class LocalStorageRepository {

    let kRememberAccount = "rememberAccount"
    let kRememberPassword = "rememberPassword"
    let kLastOverLoginLimitDate = "overLoginLimit"
    let kNeedCaptcha = "needCaptcha"
    let kRememberMe = "rememberMe"
    let kRetryCount = "retryCount"
    let kOtpRetryCount = "otpRetryCount"
    let kCountDownEndTime = "countDownEndTime"
    let kUserName = "userName"
    let KcultureCode = "cultureCode"

    func getRememberMe() -> Bool {
        return getUserDefaultValue(key: kRememberMe) ?? false
    }

    func getRemeberAccount() -> String {
        return getUserDefaultValue(key: kRememberAccount) ?? ""
    }

    func getRememberPassword() -> String {
        return getUserDefaultValue(key: kRememberPassword) ?? ""
    }

    func getLastOverLoginLimitDate() -> Date {
        return getUserDefaultValue(key: kLastOverLoginLimitDate) ?? Date()
    }

    func getNeedCaptcha() -> Bool {
        return getUserDefaultValue(key: kNeedCaptcha) ?? false
    }

    func getRetryCount() -> Int {
        return getUserDefaultValue(key: kRetryCount) ?? 0
    }

    func getOtpRetryCount() -> Int {
        return getUserDefaultValue(key: kOtpRetryCount) ?? 0
    }

    func getCountDownEndTime() -> Date? {
        return getUserDefaultValue(key: kCountDownEndTime)
    }

    func getBalanceHiddenState(gameId: String) -> Bool {
        return getUserDefaultValue(key: gameId) ?? false
    }

    func getUserName() -> String {
        return getUserDefaultValue(key: kUserName) ?? ""
    }
    
    func getCultureCode() -> String {
        return getUserDefaultValue(key: KcultureCode) ?? ""
    }
    
    func getSupportLocal() -> SupportLocale {
        return SupportLocale.Companion.init().create(language: getCultureCode())
    }
    
    func getLocalCurrency() -> AccountCurrency {
        return FiatFactory.init().create(supportLocale: getSupportLocal(), amount_: "0")
    }

    func setRememberMe(_ rememberMe: Bool?) {
        setUserDefaultValue(value: rememberMe, key: kRememberMe)
    }

    func setRemeberAccount(_ rememberAccount: String?) {
        setUserDefaultValue(value: rememberAccount, key: kRememberAccount)
    }

    func setRememberPassword(_ rememberPassword: String?) {
        setUserDefaultValue(value: rememberPassword, key: kRememberPassword)
    }

    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate: Date?) {
        setUserDefaultValue(value: lastOverLoginLimitDate, key: kLastOverLoginLimitDate)
    }

    func setNeedCaptcha(_ needCaptcha: Bool?) {
        setUserDefaultValue(value: needCaptcha, key: kNeedCaptcha)
    }

    func setRetryCount(_ count: Int) {
        setUserDefaultValue(value: count, key: kRetryCount)
    }

    func setOtpRetryCount(_ count: Int) {
        setUserDefaultValue(value: count, key: kOtpRetryCount)
    }

    func setCountDownEndTime(date: Date?) {
        setUserDefaultValue(value: date, key: kCountDownEndTime)
    }

    func setBalanceHiddenState(isHidden: Bool, gameId: String) {
        setUserDefaultValue(value: isHidden, key: gameId)
    }

    func setUserName(_ name: String) {
        setUserDefaultValue(value: name, key: kUserName)
    }
    
    func setCultureCode(_ cultureCode: String) {
        setUserDefaultValue(value: cultureCode, key: KcultureCode)
    }

    private func setUserDefaultValue<T>(value: T?, key: String) {
        if value == nil { UserDefaults.standard.removeObject(forKey: key) }
        else { UserDefaults.standard.setValue(value, forKey: key) }
        UserDefaults.standard.synchronize()
    }

    private func getUserDefaultValue<T>(key: String) -> T? {
        guard let value = UserDefaults.standard.object(forKey: key) as? T else {
            return nil
        }

        return value
    }
    
    // MARK: Save custom objects into UserDefaults
    private func setObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            UserDefaults.standard.set(data, forKey: forKey)
        } catch {
            throw ObjectSavableError.unableToEncode
        }
    }
    
    private func getObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable {
        guard let data = UserDefaults.standard.data(forKey: forKey) else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}

enum ObjectSavableError: String, LocalizedError {
    case unableToEncode = "Unable to encode object into data"
    case noValue = "No data object found for the given key"
    case unableToDecode = "Unable to decode object into given type"
    
    var errorDescription: String? {
        rawValue
    }
}
