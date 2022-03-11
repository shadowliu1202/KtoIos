import UIKit
import RxSwift
import SharedBu

class SetEmailIdentityViewController: SetIdentityProtocol {
    var setIdentityArgs: SetIdentityArgs
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var mode: ModifyMode
    
    init(mode: ModifyMode) {
        self.mode = mode
        self.setIdentityArgs = SetIdentityFactory.create(mode: mode, accountType: .email)
    }
    
    func modifyIdentity(identity: String) -> Completable {
        viewModel.modifyEmail(email: identity).do(onCompleted: {[weak self] in self?.navigateToOtpSent(email: identity) })
    }

    func handleErrors() -> Observable<Error> {
        viewModel.errors()
    }
    
    private func navigateToOtpSent(email: String) {
        let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
        let verifyNewEmailViewController = VerifyNewEmailViewController(email: email, mode: mode)
        commonVerifyOtpViewController.delegate = verifyNewEmailViewController
        NavigationManagement.sharedInstance.pushViewController(vc: commonVerifyOtpViewController)
    }
}
