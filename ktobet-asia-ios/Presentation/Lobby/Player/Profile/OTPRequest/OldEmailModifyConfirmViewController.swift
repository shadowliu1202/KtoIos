import RxSwift
import sharedbu
import UIKit

class OldEmailModifyConfirmViewController: OldAccountModifyProtocol {
  var oldAccountModifyArgs: OldAccountModifyArgs

  private var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
  private var disposeBag = DisposeBag()
  private var email = ""

  init(email: String) {
    self.email = email
    self.oldAccountModifyArgs = OldAccountModifyArgs(
      identity: email,
      title: Localize.string("profile_identity_email_step1"),
      content: Localize.string(
        "profile_identity_email_step1_description",
        email),
      failedType: ProfileEmailFailedType())
  }

  func verifyOldAccount() -> Completable {
    viewModel.verifyOldAccount(accountType: .email)
  }

  func handleErrors() -> Observable<Error> {
    viewModel.errors()
  }

  func toNextStepPage() {
    let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil)
      .instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
    commonVerifyOtpViewController.delegate = OldEmailVerifyViewController(email: email)
    NavigationManagement.sharedInstance.pushViewController(vc: commonVerifyOtpViewController)
  }
}
