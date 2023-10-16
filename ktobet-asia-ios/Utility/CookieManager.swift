import Foundation
import RxSwift

class CookieManager: LocalStorable {
  private let currentURL: URL
  private let currentDomain: String
  private let storage = HTTPCookieStorage.shared
  
  var cookies: [HTTPCookie] { currentDomainCookies() }
  var cookieHeaderValue: String {
    currentDomainCookies()
      .map { $0.name + "=" + $0.value }
      .joined(separator: ";")
  }

  init(allHosts: [String], currentURL: URL, currentDomain: String) {
    self.currentURL = currentURL
    self.currentDomain = currentDomain
    
    loadCookies()
    replaceCookiesDomain(allHosts, currentDomain)
  }
  
  private func currentDomainCookies() -> [HTTPCookie] {
    storage.cookies(for: currentURL) ?? []
  }
  
  private func loadCookies() {
    guard
      let saved: [[HTTPCookiePropertyKey: Any]] = get(key: .cookies)
    else { return }

    saved
      .compactMap { HTTPCookie(properties: $0) }
      .forEach {
        storage.setCookie($0)
      }
  }
  
  private func replaceCookiesDomain(_ allHosts: [String], _ currentDomain: String) {
    storage.cookies?
      .filter { $0.name != "kd" }
      .forEach { cookie in
        guard
          allHosts.contains(cookie.domain),
          cookie.domain != currentDomain
        else { return }

        replaceCookie(cookie, domain: currentDomain)
      }
  }
  
  private func replaceCookie(_ cookie: HTTPCookie, domain: String) {
    guard var properties = cookie.properties else { return }
    properties[.domain] = domain

    storage.deleteCookie(cookie)
    storage.setCookie(.init(properties: properties)!)
  }
  
  func replaceCulture(to cultureCode: String) {
    guard
      let cookie = HTTPCookie(properties: [
        .domain: currentDomain,
        .path: "/",
        .name: "culture",
        .value: cultureCode
      ])
    else { return }
    
    storage.setCookie(cookie)
  }
  
  func saveCookiesToUserDefault() {
    let cookies = storage.cookies?.compactMap { $0.properties }
    set(value: cookies, key: .cookies)
  }

  func removeAllCookies() {
    storage.removeCookies(since: Date(timeIntervalSince1970: 0))
    set(value: [], key: .cookies)
  }
}
