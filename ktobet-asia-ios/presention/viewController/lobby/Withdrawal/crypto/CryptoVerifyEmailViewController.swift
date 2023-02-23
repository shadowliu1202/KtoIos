import RxDataSources
import RxSwift
import UIKit

class CryptoVerifyEmailViewController: OtpViewControllerProtocol {
  private let viewModel = Injectable.resolve(CryptoVerifyViewModel.self)!
  private let disposeBag = DisposeBag()

  var commonVerifyOtpArgs: CommonVerifyOtpArgs

  init(identity: String) {
    self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: identity, verifyType: .crypto, accountType: .email)
  }

  func verify(otp: String) -> Completable {
    viewModel.verifyOtp(otp: otp, accountType: .email)
  }

  func resendOtp() -> Completable {
    viewModel.resendOtp()
  }

  func onCloseVerifyProcess() {
    Alert.shared
      .show(Localize.string("common_close_setting_hint"), Localize.string("cps_close_otp_verify_hint")) { [weak self] in
        self?.navigateToAccountsPage()
      } cancel: { }
  }

  func onExccedResendLimit() {
    Alert.shared.show(
      Localize.string("common_tip_title_warm"),
      Localize.string("common_email_otp_exeed_send_limit"),
      confirm: {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
      },
      cancel: nil)
  }

  func validateAccountType(validator: OtpValidatorDelegation) {
    let type = EnumMapper.convert(accountType: AccountType.email.rawValue)
    validator.otpAccountType.onNext(type)
  }

  func verifyOnCompleted() {
    Alert.shared.show(Localize.string("common_verify_finished"), Localize.string("cps_verify_hint"), confirm: { [weak self] in
      self?.navigateToAccountsPage()
    }, cancel: nil)
  }

  private func navigateToAccountsPage() {
    let withdrawlAccountsViewController = UIApplication.topViewController()?.navigationController?
      .viewControllers[1] as! WithdrawlLandingViewController
    withdrawlAccountsViewController.bankCardType = .crypto
    NavigationManagement.sharedInstance.popViewController(nil, to: withdrawlAccountsViewController)
  }
}
