import RxDataSources
import RxSwift
import sharedbu
import UIKit

class OtpLoginStep2ViewController: OtpViewControllerProtocol {
    struct LoginFailedType: CommonFailedTypeProtocol {
        var title: String = Localize.string("common_security_error")
        var description = Localize.string("common_warning_rapid_operation")
        var buttonTitle: String = Localize.string("common_back")
        var barItems: [UIBarButtonItem] = []
        var back: (() -> Void)? = { UIApplication.topViewController()?.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    @Injected private var viewModel: OtpLoginViewModel
    @Injected private var navViewModel: NavigationViewModel
    @Injected private var loading: Loading

    private var loadingTracker: ActivityIndicator { loading.tracker }
    private let disposeBag = DisposeBag()
    private let accountType: AccountType!

    var commonVerifyOtpArgs: CommonVerifyOtpArgs

    init(identity: String, accountType: AccountType) {
        self.accountType = accountType
        var description: String {
            switch accountType {
            case .phone:
                Localize.string("login_by_otp_step_2_mobile_description")
            case .email:
                Localize.string("login_by_otp_step_2_email_description")
            }
        }
        var identityTip: String {
            switch accountType {
            case .phone:
                Localize.string("common_otp_sent_content_mobile") + "\n" + identity
            case .email:
                Localize.string("common_otp_sent_content_email") + "\n" + identity
            }
        }
        var otpExeedSendLimitError: String {
            switch accountType {
            case .phone:
                Localize.string("login_mobile_send_limit")
            case .email:
                Localize.string("login_mail_send_limit")
            }
        }
        commonVerifyOtpArgs = CommonVerifyOtpArgs(
            title: Localize.string("login_by_otp_step_2_title"),
            description: description,
            identityTip: identityTip,
            junkTip: "",
            otpExeedSendLimitError: otpExeedSendLimitError,
            isHiddenCSBarItem: false,
            isHiddenBarTitle: false,
            commonFailedType: LoginFailedType()
        )
    }

    func verify(otp: String) -> Completable {
        viewModel.loginByVerifyCode(by: otp)
    }

    func verifyOnCompleted(onError: @escaping (Error) -> Void) {
        viewModel.getPlayerProfile()
            .flatMap { [unowned self] player in
                let setting = PlayerSetting(accountLocale: player.locale(), defaultProduct: player.defaultProduct)
                return navViewModel.initLoginNavigation(playerSetting: setting)
            }
            .trackOnDispose(loadingTracker)
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [unowned self] navigation in
                executeNavigation(navigation)
            }, onFailure: { error in
                onError(error)
            })
            .disposed(by: disposeBag)
    }

    func resendOtp() -> Completable {
        viewModel.resendOtp()
    }

    func onCloseVerifyProcess() {
        let title = Localize.string("common_confirm_leaving_title")
        let message = Localize.string("common_tip_content_unfinished")
        Alert.shared.show(title, message) {
            UIApplication.topViewController()?.dismiss(animated: true, completion: nil)
        } cancel: {}
    }

    func validateAccountType(validator: OtpValidatorDelegation) {
        let type = EnumMapper.convert(accountType: accountType.rawValue)
        validator.otpAccountType.onNext(type)
    }

    private func executeNavigation(_ navigation: NavigationViewModel.LobbyPageNavigation) {
        switch navigation {
        case .portalAllMaintenance:
            navigateToPortalMaintenancePage()
        case let .playerDefaultProduct(product):
            navigateToProductPage(product)
        case .setDefaultProduct:
            navigateToSetDefaultProductPage()
        }
    }

    private func navigateToPortalMaintenancePage() {
        Alert.shared.show(
            Localize.string("common_maintenance_notify"),
            Localize.string("common_maintenance_contact_later"),
            confirm: {
                NavigationManagement.sharedInstance.goTo(
                    storyboard: "Maintenance",
                    viewControllerId: "PortalMaintenanceViewController"
                )
            },
            cancel: nil
        )
    }

    private func navigateToProductPage(_ productType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: productType)
    }

    private func navigateToSetDefaultProductPage() {
        NavigationManagement.sharedInstance.goToSetDefaultProduct()
    }
}
