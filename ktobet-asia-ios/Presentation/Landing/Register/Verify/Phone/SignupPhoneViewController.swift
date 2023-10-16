import RxCocoa
import RxSwift
import sharedbu
import UIKit

class SignupPhoneViewController: OtpViewControllerProtocol {
  private let viewModel = Injectable.resolve(SignupPhoneViewModel.self)!
  private let disposeBag = DisposeBag()

  var commonVerifyOtpArgs: CommonVerifyOtpArgs

  init(phoneNumber: String, countryCode: String) {
    self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(
      identity: [countryCode, phoneNumber].joined(separator: " "),
      verifyType: .register,
      accountType: .phone)
  }

  func verify(otp: String) -> Completable {
    viewModel.otpVerify(otp: otp).asCompletable()
  }

  func resendOtp() -> Completable {
    viewModel.resendRegisterOtp()
  }

  func onCloseVerifyProcess() {
    Alert.shared.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
      UIApplication.topViewController()?.navigationController?.popToRootViewController(animated: true)
    } cancel: { }
  }

  func validateAccountType(validator: OtpValidatorDelegation) {
    let type = EnumMapper.convert(accountType: AccountType.phone.rawValue)
    validator.otpAccountType.onNext(type)
  }

  func onExccedResendLimit() {
    Alert.shared.show(Localize.string("common_tip_title_warm"), Localize.string("common_sms_otp_exeed_send_limit"), confirm: {
      UIApplication.topViewController()?.navigationController?.popToRootViewController(animated: true)
    }, cancel: nil)
  }

  func verifyOnCompleted() {
    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
  }
}
