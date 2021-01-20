//
//  IResetPasswordUseCase.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/29.
//

import Foundation
import share_bu
import RxSwift

protocol ResetPasswordUseCase {
    func forgetPassword(account: Account) -> Completable
    func verifyResetOtp(otp: String) -> Completable
    func resendOtp() -> Completable
    func resetPassword(password: String) -> Completable
}

class ResetPasswordUseCaseImpl : ResetPasswordUseCase {
    var authRepo : ResetPasswordRepository!
    
    init(_ authRepository : ResetPasswordRepository) {
        self.authRepo = authRepository
    }
    
    func forgetPassword(account: Account) -> Completable {
        return authRepo.requestResetPassword(account)
    }
    
    func verifyResetOtp(otp: String) -> Completable {
        return authRepo.requestResetOtp(otp).asCompletable()
    }
    
    func resendOtp() -> Completable {
        return authRepo.requestResendOtp()
    }
    
    func resetPassword(password: String) -> Completable {
        return authRepo.resetPassword(password: password)
    }
}
