import UIKit
import SharedBu
import RxSwift

class OldEmailVerifyViewController: OtpViewControllerProtocol {
    
    private let viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    private let disposeBag = DisposeBag()
    
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify: Bool = true
    
    init(email: String) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: email, verifyType: .profileOld, accountType: .email)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.verifyOldOtp(otp: otp, accountType: .email)
    }
    
    func resendOtp() -> Completable {
        viewModel.resendOtp(accountType: .email)
    }
    
    func onCloseVerifyProcess() {
        Alert.shared.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            NavigationManagement.sharedInstance.popToRootViewController()
        } cancel: { }
    }

    func validateAccountType(validator: OtpValidatorDelegation) {
        validator.otpAccountType.onNext(SharedBu.AccountType.email)
    }
    
    func verifyOnCompleted() {
        let setIdentityViewController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SetIdentityViewController") as! SetIdentityViewController
        setIdentityViewController.delegate = SetEmailIdentity(mode: .oldModify)
        NavigationManagement.sharedInstance.pushViewController(vc: setIdentityViewController)
    }
}
