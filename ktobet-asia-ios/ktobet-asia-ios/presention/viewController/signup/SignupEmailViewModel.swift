//
//  SignupEmailViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/2.
//

import Foundation
import RxSwift
import share_bu


class SignupEmailViewModel{
    
    private var registerUseCase : IRegisterUseCase!
    private var configurationUseCase : IConfigurationUseCase!
    private var authenticationUseCase : IAuthenticationUseCase!
    private var unknownError = NSError.init(domain: "unknown error", code: 99999, userInfo: ["":""])
    
    init(_ registerUseCase : IRegisterUseCase, _ configurationUseCase : IConfigurationUseCase, _ authenticationUseCase : IAuthenticationUseCase) {
        self.registerUseCase = registerUseCase
        self.configurationUseCase = configurationUseCase
        self.authenticationUseCase = authenticationUseCase
    }
    
    func checkAndLogin(_ account : String, _ password : String) -> Single<Player>{
        let checkAccount = registerUseCase.checkAccountVerification(account)
        let login = authenticationUseCase.loginFrom(account: account, pwd: password, captcha: Captcha(passCode: ""))
        return checkAccount.flatMap { (success) -> Single<Player> in
            if success { return login}
            else { return Single.error(self.unknownError) }
        }
    }
}
