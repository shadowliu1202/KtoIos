import Foundation
import RxSwift

class CookieHandler: CookieUtil {
  @Injected var portalURL: KtoURL

  private let disposeBag = DisposeBag()

  func replaceCookiesToCurrentDomain() {
    NotificationCenter.default.rx
      .notification(.NSHTTPCookieManagerCookiesChanged)
      .distinct()
      .subscribe(onNext: { [unowned self] _ in
        self.modifyCookies()
      })
      .disposed(by: disposeBag)
  }

  private func modifyCookies() {
    HTTPCookieStorage.shared
      .cookies?
      .filter { $0.name != "kd" }
      .forEach { cookie in
        guard portalURL.allHosts.contains(cookie.domain) else { return }

        if cookie.domain != portalURL.currentDomain {
          replaceCookie(cookie, domain: portalURL.currentDomain)
        }
      }
  }
  
  func replaceCulture(to cultureCode: String) {
    guard
      let cookie = HTTPCookie(properties: [
        .domain: portalURL.currentDomain,
        .path: "/",
        .name: "culture",
        .value: cultureCode
      ])
    else { return }
    
    HTTPCookieStorage.shared.setCookie(cookie)
  }
}
