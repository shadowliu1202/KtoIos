import UIKit
import RxSwift
import SharedBu

class OldMobileModifyConfirmViewController: OldAccountModifyProtocol {
    var oldAccountModifyArgs: OldAccountModifyArgs
    
    private var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    private var mobile = ""
    
    init(mobile: String) {
        self.mobile = mobile
        self.oldAccountModifyArgs = OldAccountModifyArgs(identity: mobile,
                                                         title: Localize.string("profile_identity_mobile_step1"),
                                                         content: Localize.string("profile_identity_mobile_step1_description", mobile),
                                                         failedType: ProfileMobileFailedType())
    }
    
    func verifyOldAccount() -> Completable {
        viewModel.verifyOldAccount(accountType: .phone)
    }

    func handleErrors() -> Observable<Error> {
        viewModel.errors()
    }
    
    func toNextStepPage() {
        let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
        commonVerifyOtpViewController.delegate = OldMobileVerifyViewController(mobile: mobile)
        NavigationManagement.sharedInstance.pushViewController(vc: commonVerifyOtpViewController)
    }
}
