import UIKit
import SharedBu
import RxSwift

class OldMobileVerifyViewController: OtpViewControllerProtocol {
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify: Bool = true
    
    private var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    init(mobile: String) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: mobile, verifyType: .profileOld, accountType: .phone)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.verifyOldOtp(otp: otp, accountType: .phone).do(onCompleted: {[weak self] in self?.navigateToSetMobileIdentity() })
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
    
    private func navigateToSetMobileIdentity() {
        let setIdentityViewController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "SetIdentityViewController") as! SetIdentityViewController
        setIdentityViewController.delegate = SetMobileIdentity(mode: .oldModify)
        NavigationManagement.sharedInstance.pushViewController(vc: setIdentityViewController)
    }
}
