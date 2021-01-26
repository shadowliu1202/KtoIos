//
//  SignupEmailViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/2.
//

import Foundation
import RxSwift
import RxCocoa
import share_bu


class SignupEmailViewModel{
    
    enum RegistrationVerification{
        case valid(player : Player)
        case invalid
    }
    
    private var registerUseCase : RegisterUseCase!
    private var configurationUseCase : ConfigurationUseCase!
    private var authenticationUseCase : AuthenticationUseCase!
    
    // MARK: INITIALIZE
    init(_ registerUseCase : RegisterUseCase,
         _ configurationUseCase : ConfigurationUseCase,
         _ authenticationUseCase : AuthenticationUseCase) {
        
        self.registerUseCase = registerUseCase
        self.configurationUseCase = configurationUseCase
        self.authenticationUseCase = authenticationUseCase
    }
        
    func verifyTimer()->Observable<Int>{
        let first = Observable<Int>.just(0)
        let second = Observable<Int>.interval(RxTimeInterval.seconds(5), scheduler: MainScheduler.instance)
        return Observable
            .of(first, second)
            .merge()
    }
    
    // MARK: API
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
