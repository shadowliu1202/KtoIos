import Foundation
import RxSwift
import SharedBu

class VerifyNewMobileViewController: OtpViewControllerProtocol {
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify: Bool = true
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    init(mobile: String, mode: ModifyMode) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: mobile, verifyType: .profileNew, accountType: .phone, mode: mode)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.verifyNewOtp(otp: otp, accountType: .phone).do(onCompleted: {[weak self] in self?.navigateToLoginPage() })
    }
    
    func resendOtp() -> Completable {
        viewModel.resendOtp(accountType: .phone)
    }
    
    func validateAccountType(validator: OtpValidator) {
        validator.otpAccountType.onNext(SharedBu.AccountType.phone)
    }
    
    func onCloseVerifyProcess() {
        Alert.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            NavigationManagement.sharedInstance.popToRootViewController()
        } cancel: { }
    }
    
    private func navigateToLoginPage() {
        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("profile_identity_mobile_modify_success"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
        }, cancel: nil)
    }
}
