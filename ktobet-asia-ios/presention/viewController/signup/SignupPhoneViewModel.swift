import Foundation
import RxCocoa
import RxDataSources
import RxSwift
import SharedBu

class SignupPhoneViewModel {
  private var failCount = 0
  private var registerUseCase: RegisterUseCase!

  init(_ registerUseCase: RegisterUseCase) {
    self.registerUseCase = registerUseCase
  }

  func otpVerify(otp code: String) -> Single<Player> {
    registerUseCase.loginFrom(otp: code)
  }

  func resendRegisterOtp() -> Completable {
    registerUseCase.resendRegisterOtp()
  }
}
