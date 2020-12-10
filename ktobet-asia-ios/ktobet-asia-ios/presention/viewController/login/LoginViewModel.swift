//
//  LoginViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/4.
//

import Foundation
import RxSwift
import share_bu
import RxCocoa

class LoginViewModel{
    
    private var authenticationUseCase : IAuthenticationUseCase!
    private var configurationUseCase : IConfigurationUseCase!
    var account = BehaviorRelay(value: "apptest2@qat.com")
    var password = BehaviorRelay(value: "666666")
    var captcha = BehaviorRelay(value: "")
    
    init(_ authenticationUseCase : IAuthenticationUseCase, _ configurationUseCase : IConfigurationUseCase) {
        self.authenticationUseCase = authenticationUseCase
        self.configurationUseCase = configurationUseCase
    }
    
    func loginFrom()->Single<Player>{
        let account = self.account.value
        let password = self.password.value
        let captcha = Captcha(passCode: self.captcha.value)
        return authenticationUseCase.loginFrom(account: account, pwd: password, captcha: captcha)
    }
}
