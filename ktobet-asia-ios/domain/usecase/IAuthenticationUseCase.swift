//
//  IAuthenticationUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/4.
//

import Foundation
import share_bu
import RxSwift

protocol IAuthenticationUseCase {
    func loginFrom(account: String, pwd: String, captcha: Captcha)->Single<Player>
    func logout()->Completable
    func isLogged()->Single<Bool>
}

class IAuthenticationUseCaseImpl : IAuthenticationUseCase {
    
    var authRepo : IAuthRepository!
    var playerRepo : IPlayerRepository!
    
    init(_ authRepository : IAuthRepository, _ playerRepository : IPlayerRepository) {
        self.authRepo = authRepository
        self.playerRepo = playerRepository
    }
    
    func loginFrom(account: String, pwd: String, captcha: Captcha)->Single<Player>{
        let login = authRepo.authorize(account, pwd, captcha)
        return login.flatMap { (stat) -> Single<Player> in
            if stat.status == LoginStatus.TryStatus.success{
                return self.playerRepo.loadPlayer()
            } else {
                return Single.error(NSError())
            }
        }
    }
    
    func logout()->Completable  {
        return authRepo.deAuthorize()
    }
    
    func isLogged()->Single<Bool>{
        return authRepo.checkAuthorization()
    }
}
