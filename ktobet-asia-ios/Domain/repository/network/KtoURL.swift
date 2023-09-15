import Alamofire
import RxSwift

protocol KtoURL {
  var allHosts: [String] { get }
  var currentURL: String { get }
  var currentDomain: String { get }
}

extension KtoURL {
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
      .toBlocking(timeout: 4)

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
          case .failure:
            observer(.success(nil))
          }
        }
      return Disposables.create { request.cancel() }
    }
  }
}

class PortalURL: KtoURL {
  static let shared = PortalURL()
  
  let allHosts = Configuration.hostName.values.flatMap { $0 }
  lazy var currentURL = checkingHosts(allHosts)
  lazy var currentDomain = currentURL
    .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "")
    .replacingOccurrences(of: "/", with: "")
  
  private init() { }
}

class VersionUpdateURL: KtoURL {
  static let shared = VersionUpdateURL()
  
  let allHosts = Configuration.versionUpdateHostName.values.flatMap { $0 }
  lazy var currentURL = checkingHosts(allHosts)
  lazy var currentDomain = currentURL
    .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "")
    .replacingOccurrences(of: "/", with: "")
  
  private init() { }
}
