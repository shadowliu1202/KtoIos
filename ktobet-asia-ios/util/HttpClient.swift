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
    static fileprivate var host : String {
        #if QATv
        return "https://v-qat1-mobile.affclub.xyz/"
        #elseif STAGING
        return "https://mobile.staging.support/"
        #else
        return "https://qat1-mobile.affclub.xyz/"
        #endif
    }
    static var baseUrl : URL { return URL(string: self.host)!}
}

class HttpClient {
    
    let provider : MoyaProvider<MultiTarget>!
    var session : Session { return AF}
    var host : String {return KtoURL.host}
//    var host : String { return "https://qat1.pivotsite.com/"}
    var baseUrl : URL { return KtoURL.baseUrl}
    var headers : [String : String] {
        var header : [String : String] = [:]
        //headers.add(name: "Accept-Charset", value: "UTF-8")
        header["Accept"] = "application/json"
        header["User-Agent"] = "kto-iOS/\(UIDevice.current.systemVersion) + APP v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        header["Cookie"] = {
            var token : [String] = []
            for cookie in session.sessionConfiguration.httpCookieStorage?.cookies(for: baseUrl) ?? []  {
                token.append(cookie.name + "=" + cookie.value)
            }
            return token.joined(separator: ";")
        }()
        return header
    }
    
    private(set) var debugDatas: [DebugData] = []
    
    init() {
        let formatter : NetworkLoggerPlugin.Configuration.Formatter = .init(responseData: JSONResponseDataFormatter)
        let logOptions : NetworkLoggerPlugin.Configuration.LogOptions = .verbose
        let configuration : NetworkLoggerPlugin.Configuration = .init(formatter: formatter, logOptions: logOptions)
        provider = MoyaProvider<MultiTarget>(plugins: [NetworkLoggerPlugin(configuration: configuration)]) // debug
    }

    func request(_ target: APITarget) -> Single<Response> {
        return provider
            .rx
            .request(MultiTarget(target))
            .filterSuccessfulStatusCodes()
            .flatMap({ [weak self] (response) -> Single<Response> in
                self?.printResponseData(target.iMethod.rawValue, response: response)
                if let json = try? JSON.init(data: response.data),
                   let statusCode = json["statusCode"].string,
                   let errorMsg = json["errorMsg"].string,
                   statusCode.count > 0 && errorMsg.count > 0{
                    let domain = self?.baseUrl.path ?? ""
                    let code = Int(statusCode) ?? 0
                    let error = NSError(domain: domain, code: code, userInfo: ["statusCode": statusCode , "errorMsg" : errorMsg])
                    return Single.error(error)
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
        debugData.callbackTime = "\(Date().convertdateToUTC().formatDateToStringToDay())"
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
        let dataStr = String(data: data, encoding: .utf8)!
        let s = dataStr.count > debugCharCount ? "\(dataStr.prefix(debugCharCount))...more" : dataStr
        debugData.response = "\(s)"
        
        return debugData
    }
}
