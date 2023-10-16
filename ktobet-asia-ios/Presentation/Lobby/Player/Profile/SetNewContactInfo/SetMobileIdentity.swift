import RxSwift
import sharedbu
import UIKit

class SetMobileIdentity: SetIdentityDelegate {
  private var mode: ModifyMode

  private(set) var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!

  var setIdentityArgs: SetIdentityArgs

  init(mode: ModifyMode) {
    self.mode = mode
    self.setIdentityArgs = SetIdentityFactory.create(mode: mode, accountType: .phone)
  }

  func modifyIdentity(identity: String) -> Completable {
    viewModel.modifyMobile(mobile: identity)
  }

  func handleErrors() -> Observable<Error> {
    viewModel.errors()
  }

  func navigateToOtpSent(identity: String) {
    let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil)
      .instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
    let verifyNewMobileViewController = VerifyNewMobileViewController(mobile: identity, mode: mode)
    commonVerifyOtpViewController.delegate = verifyNewMobileViewController
    NavigationManagement.sharedInstance.pushViewController(vc: commonVerifyOtpViewController)
  }
}
