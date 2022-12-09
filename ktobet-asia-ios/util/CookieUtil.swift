import Foundation

class CookieUtil {
    static let shared = CookieUtil()
    
    private init() {}
    
    func saveCookieToUserDefault() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }
        var cookieArray: [[HTTPCookiePropertyKey: Any]] = []
        for cookie in cookies {
            cookieArray.append(cookie.properties!)
        }
        
        UserDefaults.standard.setValue(cookieArray, forKey: "TmpCookies")
    }
    
    func loadCookiesFromUserDefault() {
        guard let cookieArray = UserDefaults.standard.object(forKey: "TmpCookies") as? [[HTTPCookiePropertyKey: Any]] else {
            Logger.shared.debug("no TmpCookies.")
            return
        }
        
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
}
