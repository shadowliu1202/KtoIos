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

private func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}


class HttpClient {
    
    let provider : MoyaProvider<MultiTarget>!
    var session : Session { return AF}
    var host : String {
        #if QATv
        return "https://v-qat1-mobile.affclub.xyz/"
        #else
        return "https://qat1-mobile.affclub.xyz/"
        #endif
    }
//    var host : String { return "https://qat1.pivotsite.com/"}
    var baseUrl : URL { return URL(string: self.host)!}
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
            .flatMap({ (response) -> Single<Response> in
                if let json = try? JSON.init(data: response.data),
                   let statusCode = json["statusCode"].string,
                   let errorMsg = json["errorMsg"].string,
                   statusCode.count > 0 && errorMsg.count > 0{
                    let domain = self.baseUrl.path
                    let code = Int(statusCode) ?? 0
                    let error = NSError(domain: domain, code: code, userInfo: ["errorMsg" : errorMsg])
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
}
