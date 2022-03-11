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
import SharedBu


class SignupPhoneViewModel{
    private var failCount = 0
    private var registerUseCase : RegisterUseCase!
    
    init(_ registerUseCase : RegisterUseCase) {
        self.registerUseCase = registerUseCase
    }
    
    func otpVerify(otp code: String) -> Single<Player> {
        return registerUseCase.loginFrom(otp: code)
    }
    
    func resendRegisterOtp()->Completable{
        return registerUseCase.resendRegisterOtp()
    }
}
