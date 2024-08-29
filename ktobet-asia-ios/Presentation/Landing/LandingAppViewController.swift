import RxSwift
import sharedbu
import SwiftUI
import UIKit

class LandingAppViewController: LandingViewController {
    @IBOutlet var logoItem: UIBarButtonItem!

    @Injected private var viewModel: LoginViewModel
    @Injected private var customerServiceViewModel: CustomerServiceViewModel
    @Injected private var systemStatusUseCase: ISystemStatusUseCase
    @Injected private var serviceStatusViewModel: ServiceStatusViewModel
    @Injected private var cookieManager: CookieManager
    @Injected private var alert: AlertProtocol
    @Injected private var playerConfiguration: PlayerConfiguration

    private let segueSignup = "GoToSignup"
    private let disposeBag = DisposeBag()
    private var viewDisappearBag = DisposeBag()
    private lazy var uiHostingController = createHostingViewController()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        uiHostingController.modalPresentationStyle = .fullScreen
        present(uiHostingController, animated: false, completion: nil)

        observeSystemStatus()
    }

    private func createHostingViewController() -> UIHostingController<AnyView> {
        UIHostingController(rootView:
            AnyView(
                LandingView(csViewModel: customerServiceViewModel) { [unowned self] in
                    LoginView(
                        viewModel: viewModel,
                        isForceChinese: Configuration.forceChinese,
                        onLogin: { [unowned self] pageNavigation, error in
                            if let pageNavigation {
                                executeNavigation(pageNavigation)
                            }

                            if let error {
                                switch error {
                                case is InvalidPlatformException:
                                    showServiceDownAlert()
                                default:
                                    handleErrors(error)
                                }
                            }
                        },
                        onOTPLogin: { [unowned self] in navigateToOtpLoginPage() },
                        toggleForceChinese: { [unowned self] in
                            Configuration.forceChinese.toggle()
                            recreateVC()
                        }
                    )
                }
                .onStartCS { [unowned self] in startCustomerService() }
                .onStartManuelUpdate { [unowned self] in startManuelUpdate() }
                .onShowDialog { info in
                    Alert.shared.show(
                        info.title,
                        info.message,
                        confirm: info.confirm,
                        confirmText: info.confirmText,
                        cancel: info.cancel,
                        cancelText: info.cancelText,
                        tintColor: info.tintColor
                    )
                }
                .onHandleError { [unowned self] error in
                    handleErrors(error)
                }
                .onToastMessage { [unowned self] message, style in
                    showToast(message, barImg: style)
                }
                .onEnterLobby { [unowned self] productType in
                    let lobbyNavigation: NavigationViewModel.LobbyPageNavigation =
                        if let productType, productType != .none {
                            .playerDefaultProduct(productType)
                        } else {
                            .setDefaultProduct
                        }
                    executeNavigation(lobbyNavigation)
                }
            ))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewDisappearBag = DisposeBag()
    }

    private func observeSystemStatus() {
        systemStatusUseCase
            .fetchMaintenanceStatus()
            .subscribe(
                onSuccess: { status in
                    switch onEnum(of: status) {
                    case .allPortal:
                        let portalMaintenanceViewController = PortalMaintenanceViewController()
                        portalMaintenanceViewController.modalPresentationStyle = .fullScreen
                        self.uiHostingController.present(
                            portalMaintenanceViewController,
                            animated: false,
                            completion: nil
                        )
                    case .product:
                        break
                    }
                },
                onFailure: { [weak self] error in
                    guard let self else { return }

                    handleErrors(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func navigateToPrechatSurvey() {
        let prechatVC = PrechatSurveyViewController()
        let navi = CustomServiceNavigationController(rootViewController: prechatVC)
        navi.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        uiHostingController.present(navi, animated: true, completion: nil)
    }

    private func navigateToCalling() {
        let callingVC = CallingViewController(surveyAnswers: nil)
        let navi = CustomServiceNavigationController(rootViewController: callingVC)
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        uiHostingController.present(navi, animated: false, completion: nil)
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
        alert.show(
            Localize.string("common_maintenance_notify"),
            Localize.string("common_maintenance_contact_later"),
            confirm: {
                let portalMaintenanceViewController = PortalMaintenanceViewController()
                portalMaintenanceViewController.modalPresentationStyle = .fullScreen
                self.uiHostingController.present(portalMaintenanceViewController, animated: false, completion: nil)
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

    private func showServiceDownAlert() {
        alert.show(
            Localize.string("common_tip_cn_down_title_warm"),
            Localize.string("common_cn_service_down"),
            confirm: nil,
            confirmText: Localize.string("common_cn_down_confirm")
        )
    }

    private func navigateToOtpLoginPage() {
        let storyboard = UIStoryboard(name: "OtpLogin", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()!
        uiHostingController.present(vc, animated: true, completion: nil)
    }

    @IBAction
    func backToLogin(segue: UIStoryboardSegue) {
        segue.source.presentationController?.delegate?
            .presentationControllerDidDismiss?(segue.source.presentationController!)
    }
}

extension LandingAppViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navi = segue.destination as? UINavigationController else { return }

        switch navi.viewControllers.first {
        case let vc as OtpLoginViewController:
            vc.otpStatus = sender as? OtpStatus
        default:
            break
        }
    }

    private func recreateVC() {
        uiHostingController.dismiss(animated: false)

        navigationController?.viewControllers = [LandingAppViewController()]
    }

    override func unwind(for _: UIStoryboardSegue, towards _: UIViewController) {}
}

extension LandingAppViewController {
    private struct MaintenanceError: Error {}

    private func startCustomerService() {
        serviceStatusViewModel.output.portalMaintenanceStatus
            .first()
            .flatMap { [unowned self] maintenanceStatus in
                switch onEnum(of: maintenanceStatus) {
                case .allPortal, .none:
                    Single<Bool>.error(MaintenanceError())
                case .product:
                    customerServiceViewModel.hasPreChatSurvey()
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [unowned self] hasSurvey in
                if hasSurvey {
                    navigateToPrechatSurvey()
                } else {
                    navigateToCalling()
                }
            }, onFailure: { [unowned self] error in
                switch error {
                case is MaintenanceError:
                    navigateToPortalMaintenancePage()
                case is ServiceUnavailableException:
                    navigateToCalling()
                default:
                    handleErrors(error)
                }
            })
            .disposed(by: disposeBag)
    }

    private func startManuelUpdate() {
        Configuration.isAutoUpdate = true
        appSyncViewModel.getLatestAppVersion().subscribe(onSuccess: { [weak self] inComingAppVersion in
            self?.versionAlert(inComingAppVersion)
        }, onFailure: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }

    private func alertServiceDownThenToSignUpPage() {
        let attributedText = NSAttributedString(text: Localize.string("common_cn_service_down"))
            .font(UIFont(name: "PingFangSC-Regular", size: 14)!)

        alert.show(
            Localize.string("common_tip_cn_down_title_warm"),
            attributedText,
            confirm: { [weak self] in
                self?.navigateToSignUpPage()
            },
            confirmText: Localize.string("common_cn_down_confirm")
        )
    }

    private func navigateToSignUpPage() {
        serviceStatusViewModel.output.otpService
            .subscribe(
                onSuccess: { [unowned self] otpStatus in
                    if
                        !otpStatus.isMailActive,
                        !otpStatus.isSmsActive
                    {
                        alert.show(Localize.string("common_error"), Localize.string("register_service_down"))
                    } else {
                        performSegue(withIdentifier: segueSignup, sender: nil)
                    }
                },
                onFailure: { [unowned self] in handleErrors($0) }
            )
            .disposed(by: disposeBag)
    }

    private func versionAlert(_ newVer: OnlineVersion) {
        let currentVersion = Bundle.main.currentVersion
        let title = Localize.string("update_proceed_now")
        let msg = "目前版本 : \(versionString(currentVersion)) \n最新版本 : \(versionString(newVer))"

        if isUpdateAvailable(local: currentVersion, online: newVer) {
            alert.show(title, msg, confirm: { [weak self] in
                guard let self else { return }
                syncAppVersionUpdate(viewDisappearBag)
            }, confirmText: Localize.string("update_proceed_now"), cancel: {}, cancelText: "稍後")
        } else {
            alert.show(title, msg, confirm: {}, confirmText: "無需更新", cancel: nil)
        }
    }

    private func versionString(_ version: CompareVersion) -> String {
        "\(version.apiVersion).\(version.majorVersion).\(version.minorVersion)+\(version.hotfixCompare ?? "")"
    }

    private func isUpdateAvailable(local: LocalVersion, online: OnlineVersion) -> Bool {
        local.majorVersion != online.majorVersion ||
            local.minorVersion != online.minorVersion ||
            local.apiVersion != online.apiVersion ||
            local.getUpdateAction(latestVersion: online) != .upToDate
    }
}
