import UIKit
import RxSwift
import RxDataSources

class CryptoVerifyMobileViewController: OtpViewControllerProtocol {
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    
    private let viewModel = DI.resolve(CryptoVerifyViewModel.self)!
    private let disposeBag = DisposeBag()
    
    init(identity: String) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: identity, verifyType: .crypto, accountType: .phone)
    }

    func verify(otp: String) -> Completable {
        viewModel.verifyOtp(otp: otp, accountType: .phone).do(onCompleted: {[weak self] in self?.onVerified() })
    }
    
    func resendOtp() -> Completable {
        viewModel.resendOtp()
    }
    
    func onCloseVerifyProcess() {
        Alert.show(Localize.string("common_close_setting_hint"), Localize.string("cps_close_otp_verify_hint")) {[weak self] in
            self?.navigateToAccountsPage()
        } cancel: {}
    }
    
    func onExccedResendLimit() {
        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("common_sms_otp_exeed_send_limit"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }, cancel: nil)
    }
    
    func validateAccountType(validator: OtpValidator) {
        let type = EnumMapper.convert(accountType: AccountType.phone.rawValue)
        validator.otpAccountType.onNext(type)
    }
    
    private func navigateToAccountsPage() {
        let withdrawlAccountsViewController = UIApplication.topViewController()?.navigationController?.viewControllers[1] as! WithdrawlLandingViewController
        withdrawlAccountsViewController.bankCardType = .crypto
        NavigationManagement.sharedInstance.popViewController(nil, to: withdrawlAccountsViewController)
    }
    
    private func onVerified() {
        Alert.show(Localize.string("common_verify_finished"), Localize.string("cps_verify_hint"), confirm: {[weak self] in
            self?.navigateToAccountsPage()
        }, cancel: nil)
    }
}
