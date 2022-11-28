import UIKit
import RxSwift
import RxDataSources

class ResetPasswordStep2ViewController: OtpViewControllerProtocol {

    private let viewModel = Injectable.resolve(ResetPasswordViewModel.self)!
    private let disposeBag = DisposeBag()
    private let accountType: AccountType!
    
    var commonVerifyOtpArgs: CommonVerifyOtpArgs

    init(identity: String, accountType: AccountType) {
        self.accountType = accountType
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: identity, verifyType: .resetPassword, accountType: accountType)
    }

    func verify(otp: String) -> Completable {
        viewModel.verifyResetOtp(otpCode: otp)
    }

    func resendOtp() -> Completable {
        viewModel.resendOtp()
    }

    func onCloseVerifyProcess() {
        let title = Localize.string("common_confirm_cancel_operation")
        let message = Localize.string("login_resetpassword_cancel_content")
        Alert.shared.show(title, message) {
            UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
        } cancel: { }
    }

    func onExccedResendLimit() {
        let title = Localize.string("common_tip_title_warm")
        let message = viewModel.currentAccountType() == .phone ? Localize.string("common_sms_otp_exeed_send_limit") : Localize.string("common_sms_otp_exeed_send_limit")
        Alert.shared.show(title, message, confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
        }, cancel: nil)
    }
    
    func validateAccountType(validator: OtpValidatorDelegation) {
        let type = EnumMapper.convert(accountType: accountType.rawValue)
        validator.otpAccountType.onNext(type)
    }
    
    func verifyOnCompleted() {
        let resetPasswordStep3ViewController = UIStoryboard(name: "ResetPassword", bundle: nil).instantiateViewController(withIdentifier: "ResetPasswordStep3ViewController") as! ResetPasswordStep3ViewController
        UIApplication.topViewController()?.navigationController?.pushViewController(resetPasswordStep3ViewController, animated: true)
    }
}
