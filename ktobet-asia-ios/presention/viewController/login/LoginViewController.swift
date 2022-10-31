import UIKit
import RxCocoa
import RxSwift
import SharedBu

class LoginViewController: LandingViewController {
    @IBOutlet private weak var labTitle: UILabel!
    @IBOutlet private weak var viewLoginErr: UIView!
    @IBOutlet private weak var viewLoginErrBg: UIView!
    @IBOutlet private weak var labLoginErr: UILabel!
    @IBOutlet private weak var textAccount: InputText!
    @IBOutlet private weak var labAccountErr: UILabel!
    @IBOutlet private weak var textPassword: InputPassword!
    @IBOutlet private weak var labPasswordErr: UILabel!
    @IBOutlet private weak var btnRememberMe: UIButton!
    @IBOutlet private weak var viewCaptcha: UIView!
    @IBOutlet private weak var viewCaptchaTipBg: UIView!
    @IBOutlet private weak var labCaptchaTip: UILabel!
    @IBOutlet private weak var textCaptcha: InputText!
    @IBOutlet private weak var imgCaptcha: UIImageView!
    @IBOutlet private weak var btnResendCaptcha: UIButton!
    @IBOutlet private weak var btnLogin: UIButton!
    @IBOutlet private weak var btnResetPassword: UIButton!
    @IBOutlet private weak var constraintLoginErrorHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintCaptchaHeight: NSLayoutConstraint!
    @IBOutlet private weak var toastView: ToastView!
    
    var barButtonItems: [UIBarButtonItem] = []
    
    private var captcha: UIImage?
    private lazy var customService = UIBarButtonItem.kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))
    
    private let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private let register = UIBarButtonItem.kto(.register)
    private let spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
    private let update = UIBarButtonItem.kto(.manulUpdate).isEnable(true)
    
    private let segueSignup = "GoToSignup"
    private let heightSpace = CGFloat(12)
    private let heightCaptchaView = CGFloat(257)
    private let disposeBag = DisposeBag()
    private let viewModel = DI.resolve(LoginViewModel.self)!
    private var navigationViewModel = DI.resolve(NavigationViewModel.self)!
    private let serviceStatusViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private let localStorageRepo = DI.resolve(LocalStorageRepositoryImpl.self)!
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    @IBAction func btnLoginPressed(_ sender: UIButton) {
        viewModel.login()
            .do(onSuccess: { [unowned self] _ in
                self.setRememberAccount(isRememberMe: self.btnRememberMe.isSelected)
                self.resetLoginLimit()
            })
            .flatMap({ [unowned self] (player) in
                let setting = PlayerSetting(accountLocale: player.locale(), defaultProduct: player.defaultProduct)
                return self.navigationViewModel.initLoginNavigation(playerSetting: setting)
            })
            .do(onSubscribe: { [unowned self] in
                self.btnLogin.isValid = false
            }, onDispose: { [unowned self] in
                self.btnLogin.isValid = true
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: executeNavigation, onError: handleError)
            .disposed(by: disposeBag)
    }
    
    private func setRememberAccount(isRememberMe: Bool) {
        localStorageRepo.setRememberAccount(isRememberMe ? textAccount.textContent.text! : nil)
    }
    
    private func resetLoginLimit() {
        localStorageRepo.setNeedCaptcha(nil)
        localStorageRepo.setLastOverLoginLimitDate(nil)
    }
    
    private func handleError(error: Any) {
        if let loginFail = error as? LoginException {
            switch loginFail {
            case is LoginException.Failed1to5Exception:
                showLoginError(message: Localize.string("login_invalid_username_password"))
            case is LoginException.Failed6to10Exception:
                if viewModel.relayImgCaptcha.value == nil {
                    getCaptcha()
                    showLoginError(message: Localize.string("login_invalid_username_password"))
                } else {
                    showLoginError(message: Localize.string("login_invalid_username_password_captcha"))
                }
            case is LoginException.AboveVerifyLimitation:
                showLoginError(message: Localize.string("login_invalid_lockdown"))
                viewModel.launchLoginLimitTimer()
                if imgCaptcha.image == nil { getCaptcha() }
            default: break
            }
        } else {
            handleErrors(error as! Error)
        }
    }
    
    private func showLoginError(message: String) {
        labLoginErr.text = message
        labLoginErr.layoutIfNeeded()
        viewLoginErr.isHidden = false
        constraintLoginErrorHeight.constant = labLoginErr.frame.height + heightSpace * 3
    }
    
    private func getCaptcha() {
        viewModel
            .getCaptchaImage()
            .subscribe(onSuccess: { [weak self] image in
                self?.imgCaptcha.image = image
            })
            .disposed(by: disposeBag)
    }
    
    private func executeNavigation(navigation: NavigationViewModel.LobbyPageNavigation) {
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
        Alert.shared.show(Localize.string("common_maintenance_notify"), Localize.string("common_maintenance_contact_later"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
        }, cancel: nil)
    }
    
    private func navigateToProductPage(_ productType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: productType)
    }
    
    private func navigateToSetDefaultProductPage() {
        NavigationManagement.sharedInstance.goToSetDefaultProduct()
    }
    
    @IBAction func btnRememberMePressed(_ sender: UIButton) {
        btnRememberMe.isSelected = !btnRememberMe.isSelected
    }
    
    @IBAction func btnResendCaptchaPressed(_ sender: UIButton) {
        getCaptcha()
    }

    @IBAction func backToLogin(segue: UIStoryboardSegue) {
        segue.source.presentationController?.delegate?.presentationControllerDidDismiss?(segue.source.presentationController!)
        if let vc = segue.source as? ResetPasswordStep3ViewController {
            if vc.changePasswordSuccess {
                toastView.show(on: self.view, statusTip: Localize.string("login_resetpassword_success"), img: UIImage(named: "Success"))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var barButtoms = [padding, register, spacing, customService]
        if Configuration.manualUpdate {
            let spacing2 = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
            barButtoms.append(contentsOf: [spacing2, update])
        }
        self.bind(position: .right, barButtonItems: barButtoms)
        localize()
        defaultStyle()
        setViewModel()
        
        btnResetPassword.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            self.serviceStatusViewModel.output.otpService.subscribe(onSuccess: { [weak self] otpStatus in
                if otpStatus.isSmsActive || otpStatus.isMailActive {
                    self?.performSegue(withIdentifier: ResetPasswordViewController.segueIdentifier, sender: nil)
                } else {
                    Alert.shared.show(Localize.string("common_error"), Localize.string("login_resetpassword_service_down"), confirm: { }, cancel: nil)
                }
            }, onError: { [weak self] error in
                self?.handleErrors(error)
            }).disposed(by: self.disposeBag)
        }).disposed(by: disposeBag)
    }
    
    private func localize() {
        register.title = Localize.string("common_register")
        customService.title = Localize.string("customerservice_action_bar_title")
        update.title = Localize.string("update_title")
        labLoginErr.text = Localize.string("login_invalid_username_password_captcha")
        labTitle.text = Localize.string("common_login")
        textAccount.setTitle(Localize.string("login_account_identity"))
        textPassword.setTitle(Localize.string("common_password"))
        btnRememberMe.setTitle(Localize.string("login_account_remember_me"), for: .normal)
        textCaptcha.setTitle(Localize.string("login_captcha"))
        btnResendCaptcha.setTitle(Localize.string("login_captcha_new"), for: .normal)
        btnLogin.setTitle(Localize.string("common_login"), for: .normal)
        btnResetPassword.setAttributedTitle({
            let text = NSMutableAttributedString()
            let attr1: NSAttributedString = {
                let text = Localize.string("login_tips_1") + " "
                let color = UIColor.textPrimaryDustyGray
                return NSAttributedString.init(string: text, attributes: [.foregroundColor: color])
            }()
            let attr2: NSAttributedString = {
                let text = Localize.string("login_tips_1_highlight")
                let color = UIColor.red
                return NSAttributedString.init(string: text, attributes: [.foregroundColor: color])
            }()
            text.append(attr1)
            text.append(attr2)
            return text
        }(), for: .normal)
    }
    
    private func defaultStyle() {
        btnRememberMe.isSelected = haveRememberAccount()
        viewLoginErr.isHidden = true
        viewLoginErrBg.layer.cornerRadius = 8
        viewLoginErrBg.layer.masksToBounds = true
        textAccount.setCorner(topCorner: true, bottomCorner: true)
        textPassword.setCorner(topCorner: true, bottomCorner: true)
        viewCaptcha.isHidden = true
        viewCaptchaTipBg.layer.cornerRadius = 8
        viewCaptchaTipBg.layer.masksToBounds = true
        textCaptcha.setCorner(topCorner: true, bottomCorner: true)
        btnLogin.layer.cornerRadius = 8
        btnLogin.layer.masksToBounds = true
        constraintLoginErrorHeight.constant = 0
        constraintCaptchaHeight.constant = 0
        textAccount.setKeyboardType(.emailAddress)
    }
    
    private func haveRememberAccount() -> Bool {
        return localStorageRepo.getRememberAccount().count > 0
    }
    
    private func setViewModel() {
        (textAccount.text <-> viewModel.relayAccount).disposed(by: disposeBag)
        (textPassword.text <-> viewModel.relayPassword).disposed(by: disposeBag)
        (textCaptcha.text <-> viewModel.relayCaptcha).disposed(by: disposeBag)
        
        let event = viewModel.event()
        event
            .accountValid
            .subscribe(onNext: { status in
                let message: String = {
                    switch status {
                    case .firstEmpty, .valid, .invalid: return ""
                    case .empty: return Localize.string("common_field_must_fill")
                    }
                }()
                self.showAccountValidTip(message: message)
            })
            .disposed(by: disposeBag)
        
        event
            .passwordValid
            .subscribe(onNext: { status in
                let message: String = {
                    switch status {
                    case .firstEmpty, .valid, .invalid: return ""
                    case .empty: return Localize.string("common_field_must_fill")
                    }
                }()
                self.showPasswordValidTip(message: message)
            })
            .disposed(by: disposeBag)
        
        event
            .captchaImage
            .subscribe(onNext: { image in
                if image == nil {
                    self.hideCaptcha()
                } else {
                    self.showCaptcha(cpatchaTip: Localize.string("login_enter_captcha_to_prceed"), captcha: image!)
                }
            })
            .disposed(by: disposeBag)
        
        event
            .dataValid
            .bind(to: btnLogin.rx.valid)
            .disposed(by: disposeBag)
        
        event
            .countDown
            .subscribe(onNext: { countDown in
                if countDown > 0 {
                    self.showLoginError(message: Localize.string("login_invalid_username_password_captcha"))
                }
                UIView.performWithoutAnimation {
                    self.btnLogin.setTitle({
                        var title = Localize.string("common_login")
                        if countDown > 0 { title += "(\(countDown))" }
                        return title
                    }(), for: .normal)
                    self.btnLogin.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    private func showAccountValidTip(message: String) {
        labAccountErr.text = message
        textAccount.showUnderline(message.count > 0)
        textAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
    }
    
    private func showPasswordValidTip(message: String) {
        labPasswordErr.text = message
        textPassword.showUnderline(message.count > 0)
        textPassword.setCorner(topCorner: true, bottomCorner: message.count == 0)
    }
    
    private func hideCaptcha() {
        self.viewCaptcha.isHidden = true
        self.constraintCaptchaHeight.constant = 0
    }
    
    private func showCaptcha(cpatchaTip: String, captcha: UIImage) {
        viewCaptcha.isHidden = false
        constraintCaptchaHeight.constant = btnResendCaptcha.frame.maxY
        labCaptchaTip.text = cpatchaTip
        imgCaptcha.image = captcha
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.continueLoginLimitTimer()
        addNotificationCenter()
    }
    
    private func addNotificationCenter() {
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.willEnterForegroundNotification,
                         object: nil,
                         queue: nil,
                         using: { notification in
                self.viewModel.continueLoginLimitTimer()
            })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopLoginLimitTimer()
        removeNotificationCenter()
    }
    
    private func removeNotificationCenter() {
        NotificationCenter.default.removeObserver(self)
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

extension LoginViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navi = segue.destination as? UINavigationController,
           let signupVc = navi.viewControllers.first as? SignupLanguageViewController {
            signupVc.languageChangeHandler = {
                self.localize()
                self.viewModel.refresh()
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

extension LoginViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case registerBarBtnId:
            btnSignupPressed()
        case manualUpdateBtnId:
            Configuration.isAutoUpdate = true
            appSyncViewModel.getLatestAppVersion().subscribe(onSuccess: { [weak self] (inComingAppVersion) in
                self?.versionAlert(inComingAppVersion)
            }, onError: { [weak self] in
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
        } onError: { [weak self] (error) in
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

extension LoginViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [spacing, customService]
    }
}
