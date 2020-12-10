//
//  LobbyViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/13.
//

import Foundation
import RxSwift
import share_bu


class LobbyViewModel{
    
    private var usecaseAuth : IAuthenticationUseCase!
    private var usecaseConfig : IConfigurationUseCase!

    init(_ usecaseAuth : IAuthenticationUseCase, _ usecaseConfig : IConfigurationUseCase) {
        self.usecaseAuth = usecaseAuth
        self.usecaseConfig = usecaseConfig
    }
    
    func isLogged()->Single<Bool>{
        return usecaseAuth.isLogged()
    }
    
    func logout()->Completable{
        return usecaseAuth.logout()
    }
    
    func checkPlayer(player : Player?)-> Single<Player>{
        if player != nil{
            return Single.just(player!)
        } else {
            return usecaseConfig.getPlayerInfo()
        }
    }
}

