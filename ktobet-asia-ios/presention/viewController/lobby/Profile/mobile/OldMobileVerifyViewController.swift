import RxSwift
import SharedBu
import UIKit

class OldMobileVerifyViewController: OtpViewControllerProtocol {
  private let viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
  private let disposeBag = DisposeBag()

  var commonVerifyOtpArgs: CommonVerifyOtpArgs
  var isProfileVerify = true

  init(mobile: String) {
    self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: mobile, verifyType: .profileOld, accountType: .phone)
  }

  func verify(otp: String) -> Completable {
    viewModel.verifyOldOtp(otp: otp, accountType: .phone)
  }

  func resendOtp() -> Completable {
    viewModel.resendOtp(accountType: .phone)
  }

  func onCloseVerifyProcess() {
    Alert.shared.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
      NavigationManagement.sharedInstance.popToRootViewController()
    } cancel: { }
  }

  func validateAccountType(validator: OtpValidatorDelegation) {
    validator.otpAccountType.onNext(SharedBu.AccountType.phone)
  }

  func verifyOnCompleted() {
    let setIdentityViewController = UIStoryboard(name: "Profile", bundle: nil)
      .instantiateViewController(withIdentifier: "SetIdentityViewController") as! SetIdentityViewController
    setIdentityViewController.delegate = SetMobileIdentity(mode: .oldModify)
    NavigationManagement.sharedInstance.pushViewController(vc: setIdentityViewController)
  }
}
