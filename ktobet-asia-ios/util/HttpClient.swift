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

let debugCharCount = 500

private func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}

class KtoURL {
    static fileprivate var host = Configuration.host
    static var baseUrl : URL {
        if Configuration.manualControlNetwork {
            return ManualNetworkControl.shared.baseUrl
        }
        return URL(string: self.host[Localize.getSupportLocale().cultureCode()]!)!
    }
}

class HttpClient {
    
    let provider : MoyaProvider<MultiTarget>!
    let retryProvider : MoyaProvider<MultiTarget>!
    var session : Session { return AF}
    var host : String {return KtoURL.host[Localize.getSupportLocale().cultureCode()]!}
    var baseUrl : URL { return KtoURL.baseUrl}
    var headers : [String : String] {
        var header : [String : String] = [:]
        header["Accept"] = "application/json"
        header["User-Agent"] = "AppleWebKit/" + Configuration.getKtoAgent()
        header["Cookie"] = {
            var token : [String] = []
            for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: baseUrl) ?? []  {
                token.append(cookie.name + "=" + cookie.value)
            }
            return token.joined(separator: ";")
        }()

        return header
    }

    private var retrier = APIRequestRetrier()
    private(set) var debugDatas: [DebugData] = []
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }
    
    init() {
        let configuration = logConfig()
        let session = AlamofireSessionWithRetier()
        provider = MoyaProvider<MultiTarget>(session: session, plugins: [NetworkLoggerPlugin(configuration: configuration)])
        let retrySession = AlamofireSessionWithRetier(retrier)
        retryProvider = MoyaProvider<MultiTarget>(session: retrySession, plugins: [NetworkLoggerPlugin(configuration: configuration)])
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
                    let domain = self?.baseUrl.path ?? ""
                    let code = Int(statusCode) ?? 0
                    let error = NSError(domain: domain, code: code, userInfo: ["statusCode": statusCode , "errorMsg" : errorMsg]) as Error
                    let err = ExceptionFactory.create(error)
                    return Single.error(err)
                }
                return Single.just(response)
            })
    }
    
    func getCookies()->[HTTPCookie]{
        return session.sessionConfiguration.httpCookieStorage?.cookies(for: self.baseUrl) ?? []
    }
    
    func getToken()->String{
        var token : [String] = []
        for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: self.baseUrl) ?? []  {
            token.append(cookie.name + "=" + cookie.value)
        }
        return token.joined(separator: ";")
    }
    
    func getHost() -> String {
        return host
    }

    func getCulture() -> String {
        let culture = session.sessionConfiguration.httpCookieStorage?.cookies(for: baseUrl)?.first(where: { $0.name == "culture" })?.value ?? ""
        return culture
    }
    
    func clearCookie()->Completable{
        return Completable.create { (completable) -> Disposable in
            let storage = self.session.sessionConfiguration.httpCookieStorage
            for cookie in self.getCookies(){
                storage?.deleteCookie(cookie)
            }
            completable(.completed)
            return Disposables.create {}
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
        debugData.callbackTime = "\(dateFormatter.string(from: Date()))"
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
                if let str = String(data: response.data, encoding: .utf8) {
                   return Single.just(str)
                } else {
                    let domain = self?.baseUrl.path ?? ""
                    let error = NSError(domain: domain, code: response.statusCode, userInfo: ["statusCode": response.statusCode , "errorMsg" : ""]) as Error
                    return Single.error(error)
                }
            }
    }
}

fileprivate func logConfig() -> NetworkLoggerPlugin.Configuration {
    let entry = { (identifier: String, message: String, target: TargetType) -> String in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSSXXXXX"
        let date = formatter.string(from: Date())
        return "Moya_Logger: [\(date)] \(identifier): \(message)"
    }
    let formatter : NetworkLoggerPlugin.Configuration.Formatter = .init(entry: entry, responseData: JSONResponseDataFormatter)
    let logOptions : NetworkLoggerPlugin.Configuration.LogOptions = .verbose
    let configuration : NetworkLoggerPlugin.Configuration = .init(formatter: formatter, logOptions: logOptions)
    return configuration
}

fileprivate func AlamofireSessionWithRetier(_ interceptor: APIRequestRetrier? = nil) -> Session {
    let configuration = URLSessionConfiguration.default
    configuration.headers = .default
    var evaluators: [String: ServerTrustEvaluating] = [:]
    Configuration.hostName.forEach{ evaluators[$1] = DisabledTrustEvaluator() }
    let manager = ServerTrustManager(evaluators: evaluators)
    return Session(configuration: configuration, startRequestsImmediately: false, interceptor: interceptor, serverTrustManager: manager)
}

class APIRequestRetrier: Retrier {
    let disposeBag = DisposeBag()
    
    init() {
        super.init { _, _, _, _ in }
    }
    
    override func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard Reachability?.isNetworkConnected == true else {
            Reachability?.didBecomeConnected.asObservable().subscribe(onNext: {
                guard !request.isCancelled else {
                    completion(.doNotRetry)
                    return
                }
                completion(.retry)
            }).disposed(by: disposeBag)
            
            if case .sessionTaskFailed(let err) = error as? AFError {
                Reachability?.requestErrorCallback(err)
            } else {
                Reachability?.requestErrorCallback(error)
            }
            return
        }
        completion(.doNotRetry)
    }
}
