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
                               path: "api/register/resend-otp",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func checkAccount(_ account: String)-> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/check-account",
                               method: .get,
                               task: .requestParameters(parameters: ["accountName": account], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
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
    
    func getCaptchaImage()->Single<UIImage>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/auth/get-captcha-image",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient
            .request(target)
            .mapImage()
            .map { (image) -> UIImage in
                return image as UIImage
            }
    }
    
    // MARK: 重置密碼
    func requestResetPassword(_ account: String, accountType: Int)-> Completable {
        let para = IResetPasswordRequest(account: account, accountType: accountType)
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password",
                               method: .post,
                               task: .requestJSONEncodable(para),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
     }

    func verifyResetOtp(_ params: IVerifyOtpRequest) -> Single<ResponseData<Bool>>{
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password/verify-otp",
                               method: .post,
                               task: .requestJSONEncodable(params),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Bool>.self)
     }

    func changePassword(_ request: INewPasswordRequest)-> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password/change-password",
                               method: .post,
                               task: .requestJSONEncodable(request),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }

    func resentOtp()-> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/forget-password/resend-otp",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
}
