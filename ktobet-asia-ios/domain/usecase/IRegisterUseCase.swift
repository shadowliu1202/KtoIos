//
//  IRegisterUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/29.
//

import Foundation
import share_bu
import RxSwift

protocol IRegisterUseCase  {
    func register(account: UserAccount, password: UserPassword, locale: SupportLocale) -> Completable
    func loginFrom(otp: String)-> Single<Player>
    func checkAccountVerification(_ account : String)-> Single<Bool>
    func resendRegisterOtp()->Completable
}

class IRegisterUseCaseImpl: IRegisterUseCase {

    var repoAuth : IAuthRepository!
    var repoPlayer : PlayerRepository!
    
    init( _ repoAuth : IAuthRepository, _ repoPlayer : PlayerRepository) {
        self.repoAuth = repoAuth
        self.repoPlayer = repoPlayer
    }
    
    func register(account: UserAccount, password: UserPassword, locale: SupportLocale) -> Completable {
        return repoAuth.register(account, password, locale)
    }
    
    func loginFrom(otp: String)-> Single<Player>{
        return repoAuth.authorize(otp).flatMap { (str) -> Single<Player> in
            return self.repoPlayer.loadPlayer()
        }
    }
    
    func resendRegisterOtp()->Completable{
        return repoAuth.resendRegisterOtp()
    }
    
    func checkAccountVerification(_ account : String)-> Single<Bool>{
        return repoAuth.checkRegistration(account)
    }
}
