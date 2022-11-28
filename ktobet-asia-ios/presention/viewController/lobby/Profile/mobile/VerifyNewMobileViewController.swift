import Foundation
import RxSwift
import SharedBu

class VerifyNewMobileViewController: OtpViewControllerProtocol {
    
    private let viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    private let disposeBag = DisposeBag()
    
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify: Bool = true
    
    init(mobile: String, mode: ModifyMode) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: mobile, verifyType: .profileNew, accountType: .phone, mode: mode)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.verifyNewOtp(otp: otp, accountType: .phone)
    }
    
    func resendOtp() -> Completable {
        viewModel.resendOtp(accountType: .phone)
    }
    
    func validateAccountType(validator: OtpValidatorDelegation) {
        validator.otpAccountType.onNext(SharedBu.AccountType.phone)
    }
    
    func onCloseVerifyProcess() {
        Alert.shared.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            NavigationManagement.sharedInstance.popToRootViewController()
        } cancel: { }
    }
    
    func verifyOnCompleted() {
        Alert.shared.show(Localize.string("common_tip_title_warm"), Localize.string("profile_identity_mobile_modify_success"), confirm: {
            self.logoutToLanding()
        }, cancel: nil)
    }
    
    private func logoutToLanding() {
        let playerViewModel = Injectable.resolveWrapper(PlayerViewModel.self)
        
        playerViewModel
            .logout()
            .subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
            })
            .disposed(by: disposeBag)
    }
}
