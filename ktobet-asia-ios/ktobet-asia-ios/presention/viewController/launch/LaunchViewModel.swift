//
//  LaunchViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/18.
//

import Foundation
import RxSwift

class LaunchViewModel {
    
    var usecaseAuth : IAuthenticationUseCase!
    
    init(_ usecaseAuth : IAuthenticationUseCase) {
        self.usecaseAuth = usecaseAuth
    }
    
    func checkIsLogged()->Single<Bool>{
        return usecaseAuth.isLogged()
    }
}
