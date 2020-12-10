//
//  HttpClient.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/12.
//



import Foundation
import Alamofire
import RxSwift
import SwiftyJSON


class HttpClientBack {
    
    private let session = AF
    //private let host = "https://qat1.pivotsite.com/"
    private let host = "https://qat1-mobile.affclub.xyz/"
    private let errResponseEmpty = NSError(domain: "response empty", code: 99999, userInfo: ["statusCode":99999, "errorMsg":"response empty"])
    private let errUrlNotValid = NSError(domain: "url is not valid", code: 88888, userInfo: ["statusCode":88888, "errorMsg":"url is not valid"])
    private let errDataEmpty = NSError(domain: "data empty", code: 77777, userInfo: ["statusCode":77777, "errorMsg" : "data empty"])
    
    // MARK: REQUEST
    func getAccetpEmpty<Parameters: Encodable, T1 : Decodable>(_ path : String?,  _ para : Parameters? = nil, _ header : HTTPHeaders? = nil)-> Single<T1?>{
        return Single<AFDataResponse<Data?>>.create { (single) -> Disposable in
            if let url = URL(string: self.host + (path ?? "")){
                let method = HTTPMethod.get
                let headers = self.mergeHeader(self.defaultHeader(), header)
                let encoder = URLEncodedFormParameterEncoder.default
                self.session
                    .request(url, method: method, parameters: para, encoder: encoder, headers: headers, interceptor: nil, requestModifier: nil)
                    .response { (afData) in
                        single(.success(afData))
                    }
            } else {
                single(.error(self.errUrlNotValid))
            }
            return Disposables.create {}
        }.flatMap { (afResponse) -> Single<T1?> in
            return self.parseAcceptEmpty(afResponse)
        }
    }
    
    func get<Parameters: Encodable, T1 : Decodable>(_ path : String?,  _ para : Parameters? = nil, _ header : HTTPHeaders? = nil, _ acceptDataEmpty : Bool? = false )-> Single<T1>{
        return Single<AFDataResponse<Data?>>
            .create { (single) -> Disposable in
                if let url = URL(string: self.host + (path ?? "")){
                    let method = HTTPMethod.get
                    let headers = self.mergeHeader(self.defaultHeader(), header)
                    let encoder = URLEncodedFormParameterEncoder.default
                    self.session
                        .request(url, method: method, parameters: para, encoder: encoder, headers: headers, interceptor: nil, requestModifier: nil)
                        .response { (afData) in
                            single(.success(afData))
                        }
                } else {
                    single(.error(self.errUrlNotValid))
                }
                return Disposables.create {}
            }.flatMap { (afResponse) -> Single<T1> in
                return self.parse(afResponse, acceptDataEmpty)
            }
    }
    
    func post<Parameters: Encodable, T1 : Decodable>(_ path : String?, _ para : Parameters? = nil, _ header : HTTPHeaders? = nil, _ acceptDataEmpty : Bool? = false) -> Single<T1>{
        return Single<AFDataResponse<Data?>>.create { (single) -> Disposable in
            if let url = URL(string: self.host + (path ?? "")){
                let method = HTTPMethod.post
                let headers = self.mergeHeader(self.defaultHeader(), header)
                let encoder = JSONParameterEncoder.default
                self.session.request(url, method: method, parameters: para, encoder: encoder, headers: headers, interceptor: nil, requestModifier: nil)
                    .response { (afData) in
                        single(.success(afData))
                    }
            } else {
                single(.error(self.errUrlNotValid))
            }
            return Disposables.create {}
        }.flatMap { (afResponse) -> Single<T1> in
            return self.parse(afResponse, acceptDataEmpty)
        }
    }
    
    // MARK: GET HOST
    func getHost()->String{
        return host
    }
    
    // MARK: COOKIES
    func getCookies()->[HTTPCookie]{
        guard let url = URL(string: host) else {
            return []
        }
        return session.sessionConfiguration.httpCookieStorage?.cookies(for: url) ?? []
    }
    
    func getCookieContent()->String{
        var token : [String] = []
        for cookie in getCookies()  {
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
    
    // MARK: HEADER SETTING
    private func defaultHeader()->HTTPHeaders{
        var headers = HTTPHeaders()
        //headers.add(name: "Accept", value: "application/json")
        //headers.add(name: "Accept-Charset", value: "UTF-8")
        headers.add(name: "User-Agent", value: "kto-ios/13.0")
        headers.add(name: "Cookie", value: {
            var token : [String] = []
            for cookie in self.getCookies()  {
                token.append(cookie.name + "=" + cookie.value)
            }
            return token.joined(separator: ";")
        }())
        return headers
    }
    
    private func mergeHeader(_ header1 : HTTPHeaders?, _ header2 : HTTPHeaders?)->HTTPHeaders{
        var htttpHeader = HTTPHeaders()
        header1?.forEach { (header) in
            htttpHeader.add(header)
        }
        header2?.forEach { (header) in
            htttpHeader.add(header)
        }
        return htttpHeader
    }
    
    // MARK: PARSE RESPONSE
    private func parse<T1 : Decodable>(_ afData : AFDataResponse<Data?>, _ acceptDataEmpty : Bool? = false)->Single<T1>{
        logRequestAndResponse(afData)
        return Single.create { (single) -> Disposable in
            
            var error : Swift.Error? = afData.error
            let response : T1? = try? JSONDecoder().decode(T1.self, from: afData.data ?? Data())
            let json = JSON(afData.data ?? Data())
            
            if let statusCode = json["statusCode"].string,
               let errorMsg = json["errorMsg"].string,
               statusCode.count > 0 && errorMsg.count > 0{
                error = NSError(domain: errorMsg, code: Int(statusCode) ?? 0, userInfo: ["statusCode":statusCode, "errorMsg":errorMsg])
            } else if error == nil && response == nil{
                error = self.errResponseEmpty
            } else if !(acceptDataEmpty ?? false) && error == nil && json["data"] == JSON.null{
                error = self.errDataEmpty
            }
            
            if response != nil{
                single(.success(response!))
            } else if error != nil {
                single(.error(error!))
            }
            return Disposables.create {}
        }
    }
    
    private func parseAcceptEmpty<T1 : Decodable>(_ afData : AFDataResponse<Data?>)->Single<T1?>{
        logRequestAndResponse(afData)
        return Single.create { (single) -> Disposable in
            var error : Swift.Error? = afData.error
            let response : T1? = try? JSONDecoder().decode(T1.self, from: afData.data ?? Data())
            let json = JSON(afData.data ?? Data())
            if let statusCode = json["statusCode"].string,
               let errorMsg = json["errorMsg"].string,
               statusCode.count > 0 && errorMsg.count > 0{
                error = NSError(domain: errorMsg, code: Int(statusCode) ?? 0, userInfo: ["statusCode":statusCode, "errorMsg":errorMsg])
            }
            if error != nil{
                single(.error(error!))
            } else {
                single(.success(response))
            }
            return Disposables.create {}
        }
    }
    
    // MARK: LOG
    private func logRequestAndResponse(_ afData : AFDataResponse<Data?>){
        print("<--------Request")
        print("<--------URL")
        print("\(afData.request?.url?.absoluteString ?? "")")
        print("<--------Method")
        print("\(String(describing: afData.request?.method))")
        print("<--------header")
        print("\(String(describing: afData.request?.allHTTPHeaderFields))")
        print("<--------body")
        print("\(afData.request?.httpBody?.prettyJSON ?? "")")
        print("--------->response")
        print("\(afData.data?.prettyJSON ?? "")")
    }
}

