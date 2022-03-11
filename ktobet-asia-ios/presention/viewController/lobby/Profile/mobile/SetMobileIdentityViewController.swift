import UIKit
import RxSwift
import SharedBu

class SetMobileIdentityViewController: SetIdentityProtocol {
    var setIdentityArgs: SetIdentityArgs
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var mode: ModifyMode
    
    init(mode: ModifyMode) {
        self.mode = mode
        self.setIdentityArgs = SetIdentityFactory.create(mode: mode, accountType: .phone)
    }
    
    func modifyIdentity(identity: String) -> Completable {
        viewModel.modifyMobile(mobile: identity).do(onCompleted: {[weak self] in self?.navigateToOtpSent(mobile: identity) })
    }

    func handleErrors() -> Observable<Error> {
        viewModel.errors()
    }
    
    private func navigateToOtpSent(mobile: String) {
        let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
        let verifyNewMobileViewController = VerifyNewMobileViewController(mobile: mobile, mode: mode)
        commonVerifyOtpViewController.delegate = verifyNewMobileViewController
        NavigationManagement.sharedInstance.pushViewController(vc: commonVerifyOtpViewController)
    }
}
