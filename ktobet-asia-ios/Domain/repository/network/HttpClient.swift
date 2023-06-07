import Alamofire
import Connectivity
import Foundation
import Moya
import RxBlocking
import RxSwift
import SharedBu
import SwiftyJSON
import UIKit

class HttpClient: CookieUtil {
  private let localStorageRepo: LocalStorageRepository
  private let ktoUrl: KtoURL

  private let provider: MoyaProvider<MultiTarget>
  private let retryProvider: MoyaProvider<MultiTarget>

  private(set) var debugDatas: [DebugData] = []

  var cookiesHeader: String {
    syncCookies()

    return cookies(for: host)
      .map {
        $0.name + "=" + $0.value
      }
      .joined(separator: ";")
  }

  var headers: [String: String] {
    [
      "Accept": "application/json",
      "User-Agent": "AppleWebKit/" + Configuration.getKtoAgent(),
      "Cookie": cookiesHeader,
    ]
  }

  var host: URL {
    if
      Configuration.manualControlNetwork,
      !NetworkStateMonitor.shared.isNetworkConnected
    {
      return URL(string: "\(Configuration.internetProtocol)")!
    }
    return URL(string: ktoUrl.baseURL)!
  }

  var domain: String {
    host.absoluteString
      .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "")
      .replacingOccurrences(of: "/", with: "")
  }

  var affiliateUrl: URL? {
    URL(string: "\(ktoUrl.baseURL)affiliate")
  }

  init(_ localStorageRepo: LocalStorageRepository, _ ktoUrl: KtoURL) {
    self.localStorageRepo = localStorageRepo
    self.ktoUrl = ktoUrl

    let configuration = URLSessionConfiguration.default
    configuration.headers = .default
    configuration.timeoutIntervalForRequest = .infinity

    self.provider = .init(
      session: .init(
        configuration: configuration,
        startRequestsImmediately: false),
      plugins: [NetworkLoggerPlugin.debug()])

    self.retryProvider = .init(
      session: .init(
        configuration: configuration,
        startRequestsImmediately: false,
        interceptor: APIRequestRetrier()),
      plugins: [NetworkLoggerPlugin.debug()])
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func request(_ target: TargetType) -> Single<Response> {
    getProvider(method: target.method)
      .rx
      .request(MultiTarget(target))
      .filterSuccessfulStatusCodes()
      .flatMap({ [weak self] response -> Single<Response> in
        self?.printResponseData(target.method.rawValue, response: response)

        if
          let json = try? JSON(data: response.data),
          let statusCode = json["statusCode"].string,
          let errorMsg = json["errorMsg"].string,
          statusCode.count > 0, errorMsg.count > 0
        {
          let domain = self?.host.path ?? ""
          let code = Int(statusCode) ?? 0
          let error = NSError(
            domain: domain,
            code: code,
            userInfo: ["statusCode": statusCode, "errorMsg": errorMsg]) as Error
          let err = ExceptionFactory.create(error)
          return Single.error(err)
        }

        self?.refreshLastAPISuccessDate()

        return Single.just(response)
      })
  }

  func requestJsonString(_ target: TargetType) -> Single<String> {
    getProvider(method: target.method)
      .rx
      .request(MultiTarget(target))
      .filterSuccessfulStatusCodes()
      .flatMap { [weak self] response in
        self?.printResponseData(target.method.rawValue, response: response)

        if let str = String(data: response.data, encoding: .utf8) {
          self?.refreshLastAPISuccessDate()
          return Single.just(str)
        }
        else {
          let domain = self?.host.path ?? ""
          let error = NSError(
            domain: domain,
            code: response.statusCode,
            userInfo: ["statusCode": response.statusCode, "errorMsg": ""]) as Error

          return Single.error(error)
        }
      }
  }

  private func getProvider(method: Moya.Method) -> MoyaProvider<MultiTarget> {
    method == .get ? retryProvider : provider
  }

  private func refreshLastAPISuccessDate() {
    localStorageRepo.setLastAPISuccessDate(Date())
    Logger.shared.debug("refresh API success date.")
  }
}

// MARK: - Cookie

extension HttpClient {
  func getCookies() -> [HTTPCookie] {
    cookies(for: host)
  }

  func syncCookies() {
    NotificationCenter.default.post(name: .NSHTTPCookieManagerCookiesChanged, object: nil)
  }

  func clearCookie() -> Completable {
    .create { [weak self] completable -> Disposable in
      guard let self else { return Disposables.create { } }

      self.removeAllCookies()

      completable(.completed)

      return Disposables.create { }
    }
  }
}

// MARK: - Debug Print

extension HttpClient {
  private func printResponseData(_: String, response: Response) {
    if debugDatas.count > 20 {
      debugDatas.remove(at: 0)
    }

    debugDatas.append(.init(moyaResponse: response))
  }
}

extension NetworkLoggerPlugin {
  fileprivate static func debug() -> NetworkLoggerPlugin {
    .init(
      configuration: .init(
        formatter: .init(
          entry: { identifier, message, _ in
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .iso8601)
            dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
            dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSSXXXXX"
            return "Moya_Logger: [\(dateFormatter.string(from: Date()))] \(identifier): \(message)"
          }, responseData: { data in
            guard
              let dataAsJSON = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
            else { return "" }

            return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
          }),
        logOptions: .verbose))
  }
}

// MARK: - Retrier

private class APIRequestRetrier: Retrier {
  private let disposeBag = DisposeBag()
  private var status: NetworkStateMonitor.Status?

  private var retryEvents: [(RetryResult) -> Void] = []

  init() {
    super.init { _, _, _, _ in }

    NetworkStateMonitor.shared.listener
      .subscribe(onNext: { [weak self] in
        self?.status = $0

        guard $0 == .connected else { return }

        self?.retryEvents.forEach { $0(.retry) }
        self?.retryEvents.removeAll()
      })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func retry(
    _ request: Request,
    for _: Session,
    dueTo _: Error,
    completion: @escaping (RetryResult) -> Void)
  {
    guard
      status == .disconnect,
      !request.isCancelled
    else { return }

    retryEvents.append(completion)
  }
}
