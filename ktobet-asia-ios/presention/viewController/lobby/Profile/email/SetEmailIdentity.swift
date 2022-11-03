import UIKit
import RxSwift
import SharedBu

class SetEmailIdentity: SetIdentityDelegate {    
    private(set) var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    
    private var mode: ModifyMode

    var setIdentityArgs: SetIdentityArgs
    
    init(mode: ModifyMode) {
        self.mode = mode
        self.setIdentityArgs = SetIdentityFactory.create(mode: mode, accountType: .email)
    }
    
    func modifyIdentity(identity: String) -> Completable {
        viewModel.modifyEmail(email: identity)
    }

    func handleErrors() -> Observable<Error> {
        viewModel.errors()
    }
    
    func navigateToOtpSent(identity: String) {
        let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
        let verifyNewEmailViewController = VerifyNewEmailViewController(email: identity, mode: mode)
        commonVerifyOtpViewController.delegate = verifyNewEmailViewController
        NavigationManagement.sharedInstance.pushViewController(vc: commonVerifyOtpViewController)
    }
}
