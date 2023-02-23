import Foundation

protocol CookieUtil: LocalStorable { }

extension CookieUtil {
  var storage: HTTPCookieStorage {
    HTTPCookieStorage.shared
  }

  var allCookies: [HTTPCookie] {
    storage.cookies ?? []
  }

  func cookies(for url: URL) -> [HTTPCookie] {
    storage.cookies(for: url) ?? []
  }

  func replaceCookie(
    _ cookie: HTTPCookie,
    domain: String,
    value: String? = nil)
  {
    guard var properties = cookie.properties else { return }

    storage.deleteCookie(cookie)

    properties[.domain] = domain
    if let value {
      properties[.value] = value
    }

    storage.setCookie(.init(properties: properties)!)
  }

  func removeAllCookies() {
    allCookies.forEach {
      storage.deleteCookie($0)
    }
    set(value: [], key: .cookies)
  }

  func saveCookieToUserDefault() {
    let cookies = allCookies.compactMap { $0.properties }
    set(value: cookies, key: .cookies)
  }

  func loadCookiesFromUserDefault() {
    guard
      let saved: [[HTTPCookiePropertyKey: Any]] = get(key: .cookies)
    else { return }

    saved
      .compactMap { HTTPCookie(properties: $0) }
      .forEach {
        storage.setCookie($0)
      }
  }
}
