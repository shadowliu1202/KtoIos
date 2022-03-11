import UIKit
import SharedBu
import RxSwift

class OldEmailVerifyViewController: OtpViewControllerProtocol {
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify: Bool = true
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    init(email: String) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: email, verifyType: .profileOld, accountType: .email)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.verifyOldOtp(otp: otp, accountType: .email).do(onCompleted: {[weak self] in self?.navigateToSetEmailIdentity() })
    }
    
    func resendOtp() -> Completable {
        viewModel.resendOtp(accountType: .email)
    }
    
    func onCloseVerifyProcess() {
        Alert.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            NavigationManagement.sharedInstance.popToRootViewController()
        } cancel: { }
    }

    func validateAccountType(validator: OtpValidator) {
        validator.otpAccountType.onNext(SharedBu.AccountType.email)
    }
    
    private func navigateToSetEmailIdentity() {
        let setIdentityViewController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SetIdentityViewController") as! SetIdentityViewController
        setIdentityViewController.delegate = SetEmailIdentityViewController(mode: .oldModify)
        NavigationManagement.sharedInstance.pushViewController(vc: setIdentityViewController)
    }
}
