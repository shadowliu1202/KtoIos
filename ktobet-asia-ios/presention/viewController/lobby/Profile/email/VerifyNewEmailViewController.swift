import Foundation
import RxSwift

class VerifyNewEmailViewController: OtpViewControllerProtocol {
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify: Bool = true
    
    private var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    init(email: String, mode: ModifyMode) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: email, verifyType: .profileNew, accountType: .email, mode: mode)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.verifyNewOtp(otp: otp, accountType: .email).do(onCompleted: {[weak self] in self?.navigateToLoginPage() })
    }
    
    func resendOtp() -> Completable {
        viewModel.resendOtp(accountType: .email)
    }
    
    func validateAccountType(validator: OtpValidatorDelegation) {
        let type = EnumMapper.convert(accountType: AccountType.email.rawValue)
        validator.otpAccountType.onNext(type)
    }
    
    func onCloseVerifyProcess() {
        Alert.shared.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            NavigationManagement.sharedInstance.popToRootViewController()
        } cancel: { }
    }
    
    private func navigateToLoginPage() {
        Alert.shared.show(Localize.string("common_tip_title_warm"), Localize.string("profile_identity_email_modify_success"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
        }, cancel: nil)
    }
}
