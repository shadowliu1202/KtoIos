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
    
    private var failCount = 0
    private var registerUseCase : RegisterUseCase!
    
    init(_ registerUseCase : RegisterUseCase) {
        self.registerUseCase = registerUseCase
    }
        
    func checkCodeValid()-> Observable<Bool>{
        return Observable
            .combineLatest(code1, code2, code3, code4, code5, code6)
            .map { (code1, code2, code3, code4, code5, code6) -> Bool in
                return code1.count == 1 && code2.count == 1 && code3.count == 1 && code4.count == 1 && code5.count == 1 && code6.count == 1
            }
    }
    
    func otpVerify()->Single<Player>{
        var code = ""
        for c in [code1, code2, code3, code4, code5, code6]{
            code += c.value
        }
        return registerUseCase.loginFrom(otp: code)
    }
    
    func resendRegisterOtp()->Completable{
        return registerUseCase.resendRegisterOtp()
    }
}
