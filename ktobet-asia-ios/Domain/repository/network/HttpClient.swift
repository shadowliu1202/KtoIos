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
  private let currentURL: URL
  private let cookieManager: CookieManager

  private let provider: MoyaProvider<MultiTarget>
  private let retryProvider: MoyaProvider<MultiTarget>

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

  init(_ localStorageRepo: LocalStorageRepository, _ cookieManager: CookieManager, currentURL: URL) {
    self.localStorageRepo = localStorageRepo
    self.cookieManager = cookieManager
    self.currentURL = currentURL

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
    
    configImageDownloader()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
  
  private func configImageDownloader() {
    // Unit Test will fail without this check because headers use before stub in init().
    guard !Configuration.isTesting else { return }
    
    SDWebImageDownloader.shared.config.downloadTimeout = .infinity
    
    for header in headers {
      SDWebImageDownloader.shared.setValue(header.value, forHTTPHeaderField: header.key)
    }
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
  
  func handleResponse(_ response: Response) -> Single<Response> {
    guard
      let json = try? JSON(data: response.data),
      let statusCode = json["statusCode"].string,
      let errorMsg = json["errorMsg"].string
    else { return .error(ResponseParseError(rawData: response.data)) }
      
    if statusCode.isEmpty, errorMsg.isEmpty {
      refreshLastAPISuccessDate()
      return .just(response)
    }
    else {
      return .error(ExceptionFactory.companion.create(message: errorMsg, statusCode: statusCode))
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
    Logger.shared.debug("refresh API success date.")
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
