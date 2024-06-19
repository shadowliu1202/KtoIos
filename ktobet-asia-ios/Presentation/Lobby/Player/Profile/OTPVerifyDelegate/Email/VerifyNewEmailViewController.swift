import Foundation
import RxSwift

class VerifyNewEmailViewController: OtpViewControllerProtocol {
    private let viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
    private let disposeBag = DisposeBag()

    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    var isProfileVerify = true

    init(email: String, mode: ModifyMode) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(
            identity: email,
            verifyType: .profileNew,
            accountType: .email,
            mode: mode)
    }

    func verify(otp: String) -> Completable {
        viewModel.verifyNewOtp(otp: otp, accountType: .email)
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

    func verifyOnCompleted(onError: @escaping (Error) -> Void) {
        Alert.shared.show(
            Localize.string("common_tip_title_warm"),
            Localize.string("profile_identity_email_modify_success"),
            confirm: {
                self.logoutToLanding()
            },
            cancel: nil)
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
