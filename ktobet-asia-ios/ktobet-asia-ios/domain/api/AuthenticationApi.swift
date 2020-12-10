//
//  AuthenticationApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/13.
//

import Foundation
import RxSwift
import share_bu
import Moya


class AuthenticationApi {
    
    private var httpClient : HttpClient!

    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    // MARK: 註冊
    func register(_ registerRequest : IRegisterRequest)-> Completable{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/register",
                               method: .post,
                               task: .requestJSONEncodable(registerRequest),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func verifyOtp(_ params: IVerifyOtpRequest)-> Single<ResponseData<String>>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/register/otp-verify",
                               method: .post,
                               task: .requestJSONEncodable(params),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func resendRegisterOtp()-> Completable{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/register",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func checkAccount(_ account: String)-> Single<ResponseData<Bool>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/check-account",
                               method: .post,
                               task: .requestParameters(parameters: ["accountName": account], encoding: JSONEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Bool>.self)
     }
    
    // MARK: 登入
    func login(_ account: String, _ password: String, _ captcha: Captcha)->Single<ResponseData<ILoginData>>{
        let para = LoginRequest(account: account, password: password, captcha: captcha.passCode)
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/auth/login",
                               method: .post,
                               task: .requestJSONEncodable(para),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<ILoginData>.self)
    }
    
    func isLogged()->Single<ResponseData<Bool>>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/auth/is-logged",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Bool>.self)
    }
    
    // MARK: 重置密碼
    func requestResetPassword(_ request: IResetPassword)-> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password",
                               method: .get,
                               task: .requestParameters(parameters: request.dictionary, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
     }

    func verifyResetOtp(_ request: IVerifyOtpRequest)-> Single<ResponseData<Bool>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password/verify-otp",
                               method: .get,
                               task: .requestParameters(parameters: request.dictionary, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Bool>.self)
     }

    func changePassword(_ request: INewPasswordRequest)-> Single<ResponseData<Bool>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password/verify-otp",
                               method: .get,
                               task: .requestParameters(parameters: request.dictionary, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Bool>.self)
    }

    func resentOtp()-> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "forget-password/resend-otp",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
}
