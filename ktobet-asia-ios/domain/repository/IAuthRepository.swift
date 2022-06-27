//
//  AuthRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/6.
//

import Foundation
import SharedBu
import RxSwift
import SwiftyJSON


protocol IAuthRepository {
    func register(_ account: UserAccount, _ password: UserPassword, _ locale: SupportLocale)->Completable
    func authorize(_ otp : String) -> Single<String>
    func authorize(_ account: String, _ password: String, _ captcha: Captcha) -> Single<LoginStatus>
    func deAuthorize()->Completable
    func checkAuthorization()-> Single<Bool>
    func resendRegisterOtp()-> Completable
    func checkRegistration(_ account : String)-> Single<Bool>
    func getCaptchaImage()->Single<UIImage>
}

protocol ResetPasswordRepository {
    func requestResetPassword(_ account: Account) -> Completable
    func requestResetOtp(_ otp: String) -> Single<Bool>
    func requestResendOtp() -> Completable
    func resetPassword(password: String) -> Completable
}


class IAuthRepositoryImpl : IAuthRepository {
    private var api : AuthenticationApi!
    private var httpClient : HttpClient!
    
    init(_ api : AuthenticationApi, _ httpClient : HttpClient) {
        self.api = api
        self.httpClient = httpClient
    }
    
    func register(_ account: UserAccount, _ password: UserPassword, _ locale: SupportLocale)->Completable{
        let accountType : Int = {
            if account.type.self is Account.Email{ return 1 }
            else if account.type.self is Account.Phone{ return 2 }
            else { return 0 }
        }()
        let currencyCode : String = {
            if locale.self is SupportLocale.China{ return "1" }
            else if locale.self is SupportLocale.Vietnam{ return "2" }
            else { return "0" }
        }()
        let request = IRegisterRequest(account: account.type.identity,
                                       accountType: accountType,
                                       currencyCode: currencyCode,
                                       password: password.value,
                                       realName: account.username)
        return api.register(request)
    }
    
    func authorize(_ otp : String) -> Single<String>{
        let para = IVerifyOtpRequest(verifyCode: otp)
        return api.verifyOtp(para).map { (response) -> String in
            return response.data ?? ""
        }
    }
    
    func authorize(_ account: String, _ password: String, _ captcha: Captcha) -> Single<LoginStatus>{
        return api.login(account, password, captcha).map { (response) -> LoginStatus in
            //MARK: 暫屏蔽VN註冊，待VN上線時打開
            if HttpClient().getCulture() == SupportLocale.Vietnam.shared.cultureCode() && !Configuration.isAllowedVN {
                let storage = HttpClient().session.sessionConfiguration.httpCookieStorage
                for cookie in HttpClient().getCookies() {
                    storage?.deleteCookie(cookie)
                }

                return LoginStatus.init(status: LoginStatus.TryStatus.failed1to5, isLocked: false)
            }

            let tryStatus : LoginStatus.TryStatus = {
                switch (response.data?.phase ){
                case 0: return LoginStatus.TryStatus.success
                case 1: return LoginStatus.TryStatus.failed1to5
                case 2: return LoginStatus.TryStatus.failed6to10
                case 3: return LoginStatus.TryStatus.failedabove11
                default: return LoginStatus.TryStatus.failedabove11
                }
            }()
            let isLocked = response.data?.isLocked ?? false
            self.httpClient.setDefaultToken(self.httpClient.getToken())
            return LoginStatus(status: tryStatus, isLocked: isLocked)
        }
    }
    
    func deAuthorize()->Completable{
        return httpClient.clearCookie()
    }
    
    func checkAuthorization()-> Single<Bool>{
        return api.isLogged().map { (response) -> Bool in
            return (response.data ?? false)
        }
    }
    
    func resendRegisterOtp()-> Completable  {
        return api.resendRegisterOtp()
    }
    
    func checkRegistration(_ account : String)-> Single<Bool>{
        return api.checkAccount(account).map { (response) -> Bool in
            return (response.data == "true" ? true : false) 
        }
    }
    
    func getCaptchaImage()->Single<UIImage>{
        return api.getCaptchaImage()
    }
}

extension IAuthRepositoryImpl: ResetPasswordRepository {
    func requestResetOtp(_ otp: String) -> Single<Bool> {
        let para = IVerifyOtpRequest(verifyCode: otp)
        return api.verifyResetOtp(para).map { (response) -> Bool in
            return response.data ?? false
        }
    }
    
    func requestResetPassword(_ account: Account) -> Completable {
        return api.requestResetPassword(account.identity, accountType: account is Account.Phone ? AccountType.phone.rawValue : AccountType.email.rawValue)
    }
    
    func requestResendOtp() -> Completable {
        return api.resentOtp()
    }
    
    func resetPassword(password: String) -> Completable {
        return api.changePassword(INewPasswordRequest(newPassword: password))
    }
}
