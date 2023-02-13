import Alamofire
import RxSwift

protocol KtoURL {
  var hosts: [String] { get }
  var baseURL: String { get }
  
  func observeCookiesChanged()
}

extension KtoURL {
  func observeCookiesChanged() { }
  
  func checkingHosts(_ hosts: [String]) -> String {
    mergeRequestsAndBlocking(
      hosts.map {
        headRequest($0).asObservable()
      },
      default: "\(Configuration.internetProtocol)\(hosts.first!)/")
  }

  func mergeRequestsAndBlocking(
    _ request: [Observable<String?>],
    default: String)
    -> String
  {
    let merged = Observable.merge(request)
      .compactMap { $0 }
      .timeout(.seconds(4), scheduler: MainScheduler())
      .catchAndReturn(`default`)
      .take(1)
      .toBlocking()

    do {
      return try merged.first() ?? `default`
    }
    catch {
      return `default`
    }
  }

  private func headRequest(_ hostName: String) -> Single<String?> {
    .create { observer in
      let url = "\(Configuration.internetProtocol)\(hostName)/"
      let request = Session.default
        .request(url, method: .head)
        .response { response in
          switch response.result {
          case .success:
            observer(.success(url))
          case .failure(_):
            observer(.success(nil))
          }
        }
      return Disposables.create { request.cancel() }
    }
  }
}

class PortalURL: KtoURL {
  private let cookieHandler = CookieHandler()
  
  let hosts = Configuration.hostName.values.flatMap { $0 }
  lazy var baseURL = checkingHosts(hosts)
  
  func observeCookiesChanged() {
    cookieHandler.observeCookiesChanged(
      allHosts: hosts,
      checkedHost: baseURL
        .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "")
        .replacingOccurrences(of: "/", with: "")
    )
  }
}

class VersionUpdateURL: KtoURL {
  let hosts = Configuration.versionUpdateHostName.values.flatMap { $0 }
  lazy var baseURL = checkingHosts(hosts)
}
