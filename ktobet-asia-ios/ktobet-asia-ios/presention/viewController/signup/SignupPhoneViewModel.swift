//
//  SignupPhoneViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/2.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import share_bu


class SignupPhoneViewModel{
    
    var code1 = BehaviorRelay(value: "")
    var code2 = BehaviorRelay(value: "")
    var code3 = BehaviorRelay(value: "")
    var code4 = BehaviorRelay(value: "")
    var code5 = BehaviorRelay(value: "")
    var code6 = BehaviorRelay(value: "")
    
    private var registerUseCase : IRegisterUseCase!
    
    init(_ registerUseCase : IRegisterUseCase) {
        self.registerUseCase = registerUseCase
    }
    
    func otpVerify()->Single<Player>{
        
        var code = ""
        for c in [code1, code2, code3, code4, code5, code6]{
            code += c.value
        }
        return registerUseCase.loginFrom(otp: code)
    }
}
