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
    
    enum RegistrationVerification{
        case valid(player : Player)
        case invalid
    }
    
    private var registerUseCase : IRegisterUseCase!
    private var configurationUseCase : IConfigurationUseCase!
    private var authenticationUseCase : IAuthenticationUseCase!
    private var unknownError = NSError.init(domain: "unknown error", code: 99999, userInfo: ["":""])
    
    init(_ registerUseCase : IRegisterUseCase, _ configurationUseCase : IConfigurationUseCase, _ authenticationUseCase : IAuthenticationUseCase) {
        self.registerUseCase = registerUseCase
        self.configurationUseCase = configurationUseCase
        self.authenticationUseCase = authenticationUseCase
    }
    
    func checkRegistration(_ account: String, _ password: String)-> Single<RegistrationVerification>{
        return registerUseCase
            .checkAccountVerification(account)
            .flatMap { (success) -> Single<RegistrationVerification> in
                if success{
                    return self.authenticationUseCase
                        .loginFrom(account: account, pwd: password, captcha: Captcha(passCode: ""))
                        .map { (player) -> RegistrationVerification in
                            return .valid(player: player)
                        }
                } else {
                    return Single.just(.invalid)
                }
            }
    }
    
    func resendOtp()-> Completable{
        return registerUseCase.resendRegisterOtp()
    }
}
