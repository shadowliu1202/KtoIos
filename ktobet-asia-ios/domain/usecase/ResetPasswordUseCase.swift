//
//  IResetPasswordUseCase.swift
//  ktobet-asia-ios
//
//  Created by 鄭惟臣 on 2020/12/29.
//

import Foundation
import SharedBu
import RxSwift

protocol ResetPasswordUseCase {
    func forgetPassword(account: Account) -> Completable
    func verifyResetOtp(otp: String) -> Completable
    func resendOtp() -> Completable
    func resetPassword(password: String) -> Completable
    func getRetryCount() -> Int
    func getOtpRetryCount() -> Int
    func getCountDownEndTime() -> Date?
    func setRetryCount(count: Int)
    func setOtpRetryCount(count: Int)
    func setCountDownEndTime(date: Date?)
}

class ResetPasswordUseCaseImpl : ResetPasswordUseCase {
    var authRepo: ResetPasswordRepository!
    var localRepo: LocalStorageRepository!
    
    init(_ authRepository : ResetPasswordRepository, localRepository: LocalStorageRepository) {
        self.authRepo = authRepository
        self.localRepo = localRepository
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
    
    func getRetryCount() -> Int {
        return localRepo.getRetryCount()
    }
    
    func getOtpRetryCount() -> Int {
        return localRepo.getOtpRetryCount()
    }
    
    func getCountDownEndTime() -> Date? {
        return localRepo.getCountDownEndTime()
    }
    
    func setRetryCount(count: Int) {
        localRepo.setRetryCount(count)
    }
    
    func setOtpRetryCount(count: Int) {
        localRepo.setOtpRetryCount(count)
    }
    
    func setCountDownEndTime(date: Date?) {
        localRepo.setCountDownEndTime(date: date)
    }
}
