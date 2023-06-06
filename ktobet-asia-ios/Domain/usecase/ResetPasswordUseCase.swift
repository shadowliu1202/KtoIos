import Foundation
import RxSwift
import SharedBu

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

class ResetPasswordUseCaseImpl: ResetPasswordUseCase {
  var authRepo: ResetPasswordRepository!
  var localRepo: LocalStorageRepository!

  init(_ authRepository: ResetPasswordRepository, localRepository: LocalStorageRepository) {
    self.authRepo = authRepository
    self.localRepo = localRepository
  }

  func forgetPassword(account: Account) -> Completable {
    authRepo.requestResetPassword(account)
  }

  func verifyResetOtp(otp: String) -> Completable {
    authRepo.requestResetOtp(otp).asCompletable()
  }

  func resendOtp() -> Completable {
    authRepo.requestResendOtp()
  }

  func resetPassword(password: String) -> Completable {
    authRepo.resetPassword(password: password)
  }

  func getRetryCount() -> Int {
    localRepo.getRetryCount()
  }

  func getOtpRetryCount() -> Int {
    localRepo.getOtpRetryCount()
  }

  func getCountDownEndTime() -> Date? {
    localRepo.getCountDownEndTime()
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
