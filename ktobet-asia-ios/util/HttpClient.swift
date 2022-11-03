//
//  API.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/19.
//

import Foundation
import Moya
import RxSwift
import Alamofire
import SwiftyJSON
import UIKit
import Connectivity
import SharedBu
import RxBlocking

let debugCharCount = 500

class HttpClient {
    var headers : [String : String] {
        var header : [String : String] = [:]
        header["Accept"] = "application/json"
        header["User-Agent"] = "AppleWebKit/" + Configuration.getKtoAgent()
        header["Cookie"] = {
            var token : [String] = []
            for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: host) ?? []  {
                token.append(cookie.name + "=" + cookie.value)
            }

            return token.joined(separator: ";")
        }()

        return header
    }
    var host: URL {
        get {
            if Configuration.manualControlNetwork && !NetworkStateMonitor.shared.isNetworkConnected {
                return URL(string: "https://")!
            }
            return URL(string: ktoUrl.baseUrl[localStorageRepo.getCultureCode()]!)!
        }
    }
    var domain: String {
        get {
            host.absoluteString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
        }
    }
    
    private var provider: MoyaProvider<MultiTarget>!
    private var retryProvider: MoyaProvider<MultiTarget>!
    private var session: Session { return AF }
    private var retrier = APIRequestRetrier()
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        return dateFormatter
    }
    
    private(set) var debugDatas: [DebugData] = []

    private let localStorageRepo: LocalStorageRepository
    private let ktoUrl: KtoURL

    init(_ localStorageRepo: LocalStorageRepository, _ ktoUrl: KtoURL) {
        self.localStorageRepo = localStorageRepo
        self.ktoUrl = ktoUrl
        generateSession()
    }
    
    func generateSession() {
        let uRLSessionConfiguration = URLSessionConfiguration.default
        uRLSessionConfiguration.headers = .default
        uRLSessionConfiguration.timeoutIntervalForRequest = 30
        let session = AlamofireSessionWithRetrier(configuration: uRLSessionConfiguration, startRequestsImmediately: false)
        let logConfiguration = logConfig()
        self.provider = MoyaProvider<MultiTarget>(session: session, plugins: [NetworkLoggerPlugin(configuration: logConfiguration)])
        let retrySession = AlamofireSessionWithRetrier(configuration: uRLSessionConfiguration, interceptor: retrier, startRequestsImmediately: false)
        self.retryProvider = MoyaProvider<MultiTarget>(session: retrySession, plugins: [NetworkLoggerPlugin(configuration: logConfiguration)])
    }

    func request(_ target: APITarget) -> Single<Response> {
        var provider: MoyaProvider<MultiTarget>!
        if target.method == .get {
            provider = self.retryProvider
        } else {
            provider = self.provider
        }
        return provider
            .rx
            .request(MultiTarget(target))
            .filterSuccessfulStatusCodes()
            .flatMap({ [weak self] (response) -> Single<Response> in
                self?.printResponseData(target.iMethod.rawValue, response: response)
                if let json = try? JSON.init(data: response.data),
                   let statusCode = json["statusCode"].string,
                   let errorMsg = json["errorMsg"].string,
                   statusCode.count > 0 && errorMsg.count > 0 {
                    let domain = self?.host.path ?? ""
                    let code = Int(statusCode) ?? 0
                    let error = NSError(domain: domain, code: code, userInfo: ["statusCode": statusCode , "errorMsg" : errorMsg]) as Error
                    let err = ExceptionFactory.create(error)
                    return Single.error(err)
                }
                return Single.just(response)
                    .do(onSuccess: { [unowned self] _ in
                        self?.refreshLastAPISuccessDate()
                    })
            })
    }
    
    private func refreshLastAPISuccessDate() {
        localStorageRepo.setLastAPISuccessDate(Date())
        Logger.shared.debug("refresh API success date.")
    }

    func getCookies() -> [HTTPCookie] {
        return session.sessionConfiguration.httpCookieStorage?.cookies(for: self.host) ?? []
    }

    func getCookieString() -> String {
        var token: [String] = []
        for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: self.host) ?? [] {
            token.append(cookie.name + "=" + cookie.value)
        }
        return token.joined(separator: ";")
    }

    func getCulture() -> String {
        let culture = session.sessionConfiguration.httpCookieStorage?.cookies(for: host)?.first(where: { $0.name == "culture" })?.value ?? ""
        return culture
    }
    
    func replaceCookiesDomain(_ oldURLString: String, to newURLString: String) {
        guard oldURLString != newURLString else { return }
        let oldDomain = oldURLString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
        let newDomain = newURLString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
        let storage = self.session.sessionConfiguration.httpCookieStorage
        
        for cookie in storage?.cookies ?? [] {
            if cookie.domain == oldDomain {
                var props = cookie.properties!
                props[HTTPCookiePropertyKey.domain] = newDomain
                storage!.setCookie(HTTPCookie(properties: props)!)
                storage!.deleteCookie(cookie)
            }
        }
        
        generateSession()
    }
    
    func clearCookie() -> Completable {
        return Completable.create { (completable) -> Disposable in
            let storage = self.session.sessionConfiguration.httpCookieStorage
            for cookie in self.getCookies() {
                storage?.deleteCookie(cookie)
            }
            completable(.completed)
            return Disposables.create {}
        }
    }
    
    func requestJsonString(_ target: APITarget) -> Single<String> {
        var provider: MoyaProvider<MultiTarget>!
        if target.method == .get {
            provider = self.retryProvider
        } else {
            provider = self.provider
        }
        return provider
            .rx
            .request(MultiTarget(target))
            .filterSuccessfulStatusCodes()
            .flatMap { [weak self] response in
                self?.printResponseData(target.iMethod.rawValue, response: response)
                if let str = String(data: response.data, encoding: .utf8) {
                   return Single.just(str)
                } else {
                    let domain = self?.host.path ?? ""
                    let error = NSError(domain: domain, code: response.statusCode, userInfo: ["statusCode": response.statusCode , "errorMsg" : ""]) as Error
                    return Single.error(error)
                }
            }
    }
    
    func getAffiliateUrl() -> URL? {
        if let host = self.ktoUrl.baseUrl[localStorageRepo.getCultureCode()] {
            return URL(string: "\(host)affiliate")!
        }
        return nil
    }
    
    private func logConfig() -> NetworkLoggerPlugin.Configuration {
        let entry = { [unowned self] (identifier: String, message: String, target: TargetType) -> String in
            let formatter = self.dateFormatter
            formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSSXXXXX"
            let date = formatter.string(from: Date())
            return "Moya_Logger: [\(date)] \(identifier): \(message)"
        }
        let formatter : NetworkLoggerPlugin.Configuration.Formatter = .init(entry: entry, responseData: JSONResponseDataFormatter)
        let logOptions : NetworkLoggerPlugin.Configuration.LogOptions = .verbose
        let configuration : NetworkLoggerPlugin.Configuration = .init(formatter: formatter, logOptions: logOptions)
        return configuration
    }
    
    private func JSONResponseDataFormatter(_ data: Data) -> String {
        do {
            let dataAsJSON = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
        } catch {
            return String(data: data, encoding: .utf8) ?? ""
        }
    }
    
    private func printResponseData(_ method: String, response: Response) {
        let data = self.loadResponseData(method, response: response)
        
        if self.debugDatas.count > 20 {
            self.debugDatas.remove(at: 0)
        }
        
        self.debugDatas.append(data)
    }
    
    private func loadResponseData(_ method: String, response: Response) -> DebugData {
        var debugData = DebugData()
        let formatter = self.dateFormatter
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        debugData.callbackTime = "\(formatter.string(from: Date()))"
        debugData.url = "\(String(describing: (response.request?.url)!))"
        if response.request?.allHTTPHeaderFields != nil {
            debugData.headers = "\((response.request?.allHTTPHeaderFields)!)"
        }
        
        if response.request?.httpBody != nil {
            var b = String(describing: String(data: (response.request?.httpBody)!, encoding: String.Encoding.utf8)!).replacingOccurrences(of: "\\", with: "")
            b = b.count < debugCharCount ? b : b.prefix(debugCharCount) + "...more"
            debugData.body = "\(b)"
        }
        
        let data = response.data
        if let dataStr = String(data: data, encoding: .utf8) {
            let s = dataStr.count > debugCharCount ? "\(dataStr.prefix(debugCharCount))...more" : dataStr
            debugData.response = "\(s)"
        } else {
            debugData.response = "response is empty"
        }
        
        return debugData
    }
    
}

class APIRequestRetrier: Retrier {
    private let disposeBag = DisposeBag()
    
    init() {
        super.init { _, _, _, _ in }
    }
    
    override func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard NetworkStateMonitor.shared.isNetworkConnected == true else {
            NetworkStateMonitor.shared.didBecomeConnected.asObservable().subscribe(onNext: {
                guard !request.isCancelled else {
                    completion(.doNotRetry)
                    return
                }
                completion(.retry)
            }).disposed(by: disposeBag)
            
            if case .sessionTaskFailed(let err) = error as? AFError {
                NetworkStateMonitor.shared.requestErrorCallback(err)
            } else {
                NetworkStateMonitor.shared.requestErrorCallback(error)
            }
            return
        }
        completion(.doNotRetry)
    }
}

func AlamofireSessionWithRetrier(configuration: URLSessionConfiguration,
                                 interceptor: APIRequestRetrier? = nil,
                                 startRequestsImmediately: Bool = true) -> Session {
    return Session(configuration: configuration, startRequestsImmediately: startRequestsImmediately, interceptor: interceptor)
}
