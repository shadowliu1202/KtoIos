import UIKit
import SwiftUI
import RxSwift
import SharedBu

class NewLoginViewController: LandingViewController {
    
    @IBOutlet weak var logoItem: UIBarButtonItem!
    
    var barButtonItems: [UIBarButtonItem] = []
    
    private let segueSignup = "GoToSignup"
    
    private let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private let register = UIBarButtonItem.kto(.register)
    private let spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
    private let update = UIBarButtonItem.kto(.manulUpdate).isEnable(true)
    
    private let disposeBag = DisposeBag()
    
    private lazy var customService = UIBarButtonItem.kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))
    private lazy var serviceStatusViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.info("\(type(of: self)) viewDidLoad.")
        logoItem.image = UIImage(named: "KTO (D)")?.withRenderingMode(.alwaysOriginal)
        var barButtoms = [padding, register, spacing, customService]
        if Configuration.manualUpdate {
            let spacing2 = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
            barButtoms.append(contentsOf: [spacing2, update])
        }
        self.bind(position: .right, barButtonItems: barButtoms)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeSystemStatus()
    }
    
    private func observeSystemStatus() {
        serviceStatusViewModel.output.portalMaintenanceStatus
            .subscribe(
                onNext: { status in
                    switch status {
                    case is MaintenanceStatus.AllPortal:
                        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
                    default:
                        break
                    }
                },
                onError: { [weak self] error in
                    self?.handleErrors(error)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func localize() {
        register.title = Localize.string("common_register")
        customService.title = Localize.string("customerservice_action_bar_title")
        update.title = Localize.string("update_title")
    }
    
    @IBSegueAction func segueToHostingController(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: LoginView(onLogin: { pageNavigation, generalError in
            if let pageNavigation = pageNavigation {
                self.executeNavigation(pageNavigation)
            }
            
            if let generalError = generalError {
                self.handleErrors(generalError)
            }
        }, onResetPassword: {
            self.navigateToResetPasswordPage()
        }))
    }
    
    private func executeNavigation(_ navigation: NavigationViewModel.LobbyPageNavigation) {
        switch navigation {
        case .portalAllMaintenance:
            navigateToPortalMaintenancePage()
        case .playerDefaultProduct(let product):
            navigateToProductPage(product)
        case .setDefaultProduct:
            navigateToSetDefaultProductPage()
        }
    }

    private func navigateToPortalMaintenancePage() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
    }
    
    private func navigateToProductPage(_ productType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: productType)
    }
    
    private func navigateToMaintainPage(_ type: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: type, isMaintenance: true)
    }
    
    private func alertMaintenance(product: ProductType, onConfirm: @escaping (() -> Void)) {
        Alert.shared.show(Localize.string("common_maintenance_notify"),
                   Localize.string("common_default_product_maintain_content", StringMapper.parseProductTypeString(productType: product)),
                   confirm: onConfirm, cancel: nil)
    }
    
    private func navigateToSetDefaultProductPage() {
        NavigationManagement.sharedInstance.goToSetDefaultProduct()
    }
    
    private func navigateToSignUpPage() {
        serviceStatusViewModel.output.otpService.subscribe { [weak self] (otpStatus) in
            if !otpStatus.isMailActive && !otpStatus.isSmsActive {
                let title = Localize.string("common_error")
                let message = Localize.string("register_service_down")
                Alert.shared.show(title, message, confirm: nil, cancel: nil)
            } else {
                self?.performSegue(withIdentifier: self!.segueSignup, sender: nil)
            }
        } onFailure: { [weak self] (error) in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    @IBAction func backToLogin(segue: UIStoryboardSegue) {
        segue.source.presentationController?.delegate?.presentationControllerDidDismiss?(segue.source.presentationController!)
        if let vc = segue.source as? ResetPasswordStep3ViewController {
            if vc.changePasswordSuccess {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
                toastView.show(on: nil, statusTip: Localize.string("login_resetpassword_success"), img: UIImage(named: "Success"))
            }
        }
    }
    
    private func navigateToResetPasswordPage() {
        self.serviceStatusViewModel.output.otpService.subscribe(onSuccess: { [weak self] otpStatus in
            if otpStatus.isSmsActive || otpStatus.isMailActive {
                self?.performSegue(withIdentifier: ResetPasswordViewController.segueIdentifier, sender: nil)
            } else {
                Alert.shared.show(Localize.string("common_error"), Localize.string("login_resetpassword_service_down"), confirm: { }, cancel: nil)
            }
        }, onFailure: { [weak self] error in
            self?.handleErrors(error)
        }).disposed(by: self.disposeBag)
    }
    
    override func updateStrategy(_ incoming: Version, _ superSignStatus: SuperSignStatus) {
        super.updateStrategy(incoming, superSignStatus)
        let action = Bundle.main.currentVersion.getUpdateAction(latestVersion: incoming)
        if action == .optionalupdate {
            doOptionalUpdateConfirm(incoming, superSignStatus)
        }
    }
    
    private func doOptionalUpdateConfirm(_ incoming: Version,_ superSignStatus: SuperSignStatus?) {
        if superSignStatus?.isMaintenance == false {
            confirmUpdate(incoming.apkLink)
        }
    }
}

extension NewLoginViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navi = segue.destination as? UINavigationController,
           let signupVc = navi.viewControllers.first as? SignupLanguageViewController {
            signupVc.languageChangeHandler = {
                self.localize()
            }
            signupVc.presentationController?.delegate = self
        }
        if let navi = segue.destination as? UINavigationController,
           let vc = navi.viewControllers.first as? ResetPasswordViewController {
            vc.presentationController?.delegate = self
        }
    }
    
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) { }
}

extension NewLoginViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case registerBarBtnId:
            btnSignupPressed()
        case manualUpdateBtnId:
            Configuration.isAutoUpdate = true
            appSyncViewModel.getLatestAppVersion().subscribe(onSuccess: { [weak self] (inComingAppVersion) in
                self?.versionAlert(inComingAppVersion)
            }, onFailure: { [weak self] in
                self?.handleErrors($0)
            }).disposed(by: disposeBag)
            break
        default:
            break
        }
    }
    
    private func btnSignupPressed() {
        serviceStatusViewModel.output.otpService.subscribe { [weak self] (otpStatus) in
            if !otpStatus.isMailActive && !otpStatus.isSmsActive {
                let title = Localize.string("common_error")
                let message = Localize.string("register_service_down")
                Alert.shared.show(title, message, confirm: nil, cancel: nil)
            } else {
                self?.performSegue(withIdentifier: self!.segueSignup, sender: nil)
            }
        } onFailure: { [weak self] (error) in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    private func versionAlert(_ newVer: Version) {
        let currentVersion = Bundle.main.currentVersion
        let currentVersionCode = currentVersion.versionCode
        let newVersionCode = newVer.versionCode
        let title = Localize.string("update_proceed_now")
        let msg = "目前版本 : \(currentVersion)+\(currentVersionCode) \n最新版本 : \(newVer)+\(newVersionCode)"
        if currentVersion.compareTo(other: newVer) < 0 {
            Alert.shared.show(title, msg, confirm: {
                self.syncAppVersionUpdate(self.versionSyncDisposeBag)
            }, confirmText: Localize.string("update_proceed_now"), cancel: {}, cancelText: "稍後")
        } else {
            Alert.shared.show(title, msg, confirm: { }, confirmText: "無需更新", cancel: nil)
        }
    }
    
}

extension NewLoginViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [spacing, customService]
    }
}
