import UIKit
import RxSwift
import RxDataSources

class ResetPasswordStep2ViewController: OtpViewControllerProtocol {
    var commonVerifyOtpArgs: CommonVerifyOtpArgs

    private var viewModel = DI.resolve(ResetPasswordViewModel.self)!
    private var disposeBag = DisposeBag()
    private var accountType: AccountType!

    init(identity: String, accountType: AccountType) {
        self.accountType = accountType
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: identity, verifyType: .resetPassword, accountType: accountType)
    }

    func verify(otp: String) -> Completable {
        viewModel.verifyResetOtp(otpCode: otp).do(onCompleted: {[weak self] in self?.onVerified() })
    }

    func resendOtp() -> Completable {
        viewModel.resendOtp()
    }

    func onCloseVerifyProcess() {
        let title = Localize.string("common_confirm_cancel_operation")
        let message = Localize.string("login_resetpassword_cancel_content")
        Alert.show(title, message) {
            UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
        } cancel: { }
    }

    func onExccedResendLimit() {
        let title = Localize.string("common_tip_title_warm")
        let message = viewModel.currentAccountType() == .phone ? Localize.string("common_sms_otp_exeed_send_limit") : Localize.string("common_sms_otp_exeed_send_limit")
        Alert.show(title, message, confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }, cancel: nil)
    }
    
    func validateAccountType(validator: OtpValidator) {
        let type = EnumMapper.convert(accountType: accountType.rawValue)
        validator.otpAccountType.onNext(type)
    }
    
    private func onVerified() {
        let resetPasswordStep3ViewController = UIStoryboard(name: "ResetPassword", bundle: nil).instantiateViewController(withIdentifier: "ResetPasswordStep3ViewController") as! ResetPasswordStep3ViewController
        UIApplication.topViewController()?.navigationController?.pushViewController(resetPasswordStep3ViewController, animated: true)
    }
}
