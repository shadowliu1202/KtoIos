import Alamofire
import Connectivity
import Foundation
import Moya
import RxBlocking
import RxSwift
import SDWebImage
import sharedbu
import SwiftyJSON
import UIKit

class HttpClient {
  private let localStorageRepo: LocalStorageRepository
  private let cookieManager: CookieManager
  private let currentURL: URL

  private var provider: MoyaProvider<MultiTarget>!
  private var retryProvider: MoyaProvider<MultiTarget>!

  private(set) var debugDatas: [DebugData] = []

  var headers: [String: String] {
    [
      "Accept": "application/json",
      "User-Agent": "AppleWebKit/" + Configuration.getKtoAgent(),
      "Cookie": cookieManager.cookieHeaderValue,
    ]
  }

  var host: URL {
    if
      Configuration.manualControlNetwork,
      !NetworkStateMonitor.shared.isNetworkConnected
    {
      return URL(string: "\(Configuration.internetProtocol)")!
    }
    return currentURL
  }

  init(
    _ localStorageRepo: LocalStorageRepository,
    _ cookieManager: CookieManager,
    currentURL: URL,
    locale: SupportLocale,
    provider: MoyaProvider<MultiTarget>? = nil)
  {
    self.localStorageRepo = localStorageRepo
    self.cookieManager = cookieManager
    self.currentURL = currentURL

    cookieManager.setCulture(to: locale)
    setupProvider(provider)
  }

  private func setupProvider(_ provider: MoyaProvider<MultiTarget>?) {
    let configuration = URLSessionConfiguration.default
    configuration.headers = .default
    configuration.timeoutIntervalForRequest = .infinity

    self.provider = provider ?? .init(
      session: .init(
        configuration: configuration,
        startRequestsImmediately: false),
      plugins: [
        NetworkLoggerPlugin.debug(),
        TimeoutRecorder()
      ])

    self.retryProvider = provider ?? .init(
      session: .init(
        configuration: configuration,
        startRequestsImmediately: false,
        interceptor: APIRequestRetrier()),
      plugins: [
        NetworkLoggerPlugin.debug(),
        TimeoutRecorder()
      ])
  }
  
  func request(_ target: TargetType) -> Single<Response> {
    getProvider(method: target.method)
      .rx
      .request(MultiTarget(target))
      .filterSuccessfulStatusCodes()
      .flatMap({ [weak self] response -> Single<Response> in
        self?.printResponseData(target.method.rawValue, response: response)
        guard let self else { return .error(KTOError.LostReference) }

        return self.handleResponse(response)
      })
  }
  
  private func handleResponse(_ response: Response) -> Single<Response> {
    if
      let json = try? JSON(data: response.data),
      let statusCode = json["statusCode"].string,
      let errorMsg = json["errorMsg"].string,
      !statusCode.isEmpty
    {
      return .error(ExceptionFactory.companion.create(message: errorMsg, statusCode: statusCode))
    }
    else {
      refreshLastAPISuccessDate()
      return .just(response)
    }
  }
  
  @available(*, deprecated, message: "Target should create in HTTPClient.")
  func requestJsonString(_ target: TargetType) -> Single<String> {
    request(target)
      .flatMap { [weak self] response in
        self?.printResponseData(target.method.rawValue, response: response)
        
        guard
          let json = try? JSON(data: response.data),
          let rawString = json.rawString()
        else { return .error(ResponseParseError(rawData: response.data)) }
        
        return .just(rawString)
      }
  }
  
  func requestJsonString(
    path: String,
    method: Moya.Method,
    task: Moya.Task? = nil) -> Single<String>
  {
    requestJsonString(
      NewAPITarget(
        path: path,
        method: method,
        task: task,
        baseURL: host,
        headers: headers))
  }

  private func getProvider(method: Moya.Method) -> MoyaProvider<MultiTarget> {
    method == .get ? retryProvider : provider
  }

  private func refreshLastAPISuccessDate() {
    localStorageRepo.setLastAPISuccessDate(Date())
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
  private var status: NetworkStatus?

  private var retryEvents: [(RetryResult) -> Void] = []

  init() {
    super.init { _, _, _, _ in }

    NetworkStateMonitor.shared.status
      .subscribe(onNext: { [weak self] in
        self?.status = $0

        guard $0 == .connected else { return }

        self?.retryEvents.forEach { $0(.retry) }
        self?.retryEvents.removeAll()
      })
      .disposed(by: disposeBag)
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
