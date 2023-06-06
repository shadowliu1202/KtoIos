import Foundation
import RxSwift

class CookieHandler: CookieUtil {
  @Injected private var localRepo: LocalStorageRepository

  private let disposeBag = DisposeBag()

  func observeCookiesChanged(
    allHosts: [String],
    checkedHost: String)
  {
    NotificationCenter.default.rx
      .notification(.NSHTTPCookieManagerCookiesChanged)
      .distinct()
      .subscribe(onNext: { [unowned self] _ in
        self.modifyCookies(allHosts: allHosts, to: checkedHost)
      })
      .disposed(by: disposeBag)
  }

  private func modifyCookies(allHosts: [String], to domain: String) {
    HTTPCookieStorage.shared
      .cookies?
      .filter { $0.name != "kd" }
      .forEach { cookie in
        guard allHosts.contains(cookie.domain) else { return }

        if cookie.name == "culture" {
          replaceCookie(cookie, domain: domain, value: localRepo.getCultureCode())
        }
        else if cookie.domain != domain {
          replaceCookie(cookie, domain: domain)
        }
      }
  }
}
