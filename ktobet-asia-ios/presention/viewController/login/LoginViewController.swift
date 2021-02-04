import UIKit
import RxCocoa
import RxSwift
import share_bu

class LoginViewController: UIViewController {
    @IBOutlet private weak var btnSignup : UIBarButtonItem!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var viewLoginErr : UIView!
    @IBOutlet private weak var viewLoginErrBg : UIView!
    @IBOutlet private weak var labLoginErr : UILabel!
    @IBOutlet private weak var textAccount : InputText!
    @IBOutlet private weak var labAccountErr : UILabel!
    @IBOutlet private weak var textPassword : InputPassword!
    @IBOutlet private weak var labPasswordErr : UILabel!
    @IBOutlet private weak var btnRememberMe : UIButton!
    @IBOutlet private weak var viewCaptcha : UIView!
    @IBOutlet private weak var viewCaptchaTipBg : UIView!
    @IBOutlet private weak var labCaptchaTip : UILabel!
    @IBOutlet private weak var textCaptcha : InputText!
    @IBOutlet private weak var imgCaptcha : UIImageView!
    @IBOutlet private weak var btnResendCaptcha : UIButton!
    @IBOutlet private weak var btnLogin : UIButton!
    @IBOutlet private weak var btnResetPassword : UIButton!
    @IBOutlet private weak var constraintLoginErrorHeight : NSLayoutConstraint!
    @IBOutlet private weak var constraintCaptchaHeight : NSLayoutConstraint!
    @IBOutlet private weak var toastView: ToastView!
    
    private var captcha : UIImage?
    private let segueSignup = "GoToSignup"
    private let heightSpace = CGFloat(12)
    private let heightCaptchaView = CGFloat(257)
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(LoginViewModel.self)!
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        defaulStyle()
        setViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.continueLoginLimitTimer()
        addNotificationCenter()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopLoginLimitTimer()
        removeNotificationCenter()
    }
    
    deinit {}
    
    // MARK: NOTIFICATION
    private func addNotificationCenter(){
        NotificationCenter
            .default
            .addObserver(forName: UIApplication.willEnterForegroundNotification,
                         object: nil,
                         queue: nil,
                         using: {notification in
                            self.viewModel.continueLoginLimitTimer()
                         })
    }
    
    private func removeNotificationCenter(){
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: METHOD
    func localize(){
        labLoginErr.text = Localize.string("login_invalid_username_password_captcha")
        btnSignup.title = Localize.string("common_register")
        labTitle.text = Localize.string("common_login")
        textAccount.setTitle(Localize.string("login_account_identity"))
        textPassword.setTitle(Localize.string("common_password"))
        btnRememberMe.setTitle(Localize.string("login_account_remember_me"), for: .normal)
        textCaptcha.setTitle(Localize.string("login_captcha"))
        btnResendCaptcha.setTitle(Localize.string("login_captcha_new"), for: .normal)
        btnLogin.setTitle(Localize.string("common_login"), for: .normal)
        btnResetPassword.setAttributedTitle({
            let text = NSMutableAttributedString()
            let attr1 : NSAttributedString = {
                let text = Localize.string("login_tips_1") + " "
                let color = UIColor.textPrimaryDustyGray
                return NSAttributedString.init(string: text, attributes: [.foregroundColor : color])
            }()
            let attr2 : NSAttributedString = {
                let text = Localize.string("login_tips_1_highlight")
                let color = UIColor.red
                return NSAttributedString.init(string: text, attributes: [.foregroundColor : color])
            }()
            text.append(attr1)
            text.append(attr2)
            return text
        }(), for: .normal)
    }
    
    func defaulStyle(){
        btnRememberMe.isSelected = viewModel.isRememberMe()
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
    }
    
    func setViewModel(){
        (textAccount.text <-> viewModel.relayAccount).disposed(by: disposeBag)
        (textPassword.text <-> viewModel.relayPassword).disposed(by: disposeBag)
        (textCaptcha.text <-> viewModel.relayCaptcha).disposed(by: disposeBag)
        
        let event = viewModel.event()
        event
            .accountValid
            .subscribe(onNext: {status in
                let message : String = {
                    switch status{
                    case .firstEmpty, .valid, .invalid: return ""
                    case .empty: return Localize.string("common_field_must_fill")
                    }
                }()
                self.showAccountValidtip(message: message)
            })
            .disposed(by: disposeBag)
        
        event
            .passwordValid
            .subscribe(onNext: {status in
                let message : String = {
                    switch status{
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
                self.btnLogin.setTitle({
                    var title = Localize.string("common_login")
                    if countDown > 0{ title += "(\(countDown))" }
                    return title
                }(), for: .normal)
            })
            .disposed(by: disposeBag)
        
    }
    
    // MARK: ERROR
    private func handleError(error : Any){
        if let loginFail = error as? LoginError, let status = loginFail.status{
            switch status {
            case .failed1to5:
                showLoginError(message: Localize.string("login_invalid_username_password"))
            case .failed6to10:
                if viewModel.relayImgCaptcha.value == nil {
                    getCaptcha()
                    showLoginError(message: Localize.string("login_invalid_username_password"))
                } else {
                    showLoginError(message: Localize.string("login_invalid_username_password_captcha"))
                }
            case .failedabove11:
                showLoginError(message: Localize.string("login_invalid_lockdown"))
                viewModel.launchLoginLimitTimer()
                if imgCaptcha.image == nil { getCaptcha() }
            default: break
            }
        }
    }
    
    // MARK: PRESENT TIP
    func showLoginError( message : String){
        labLoginErr.text = message
        labLoginErr.layoutIfNeeded()
        viewLoginErr.isHidden = false
        constraintLoginErrorHeight.constant = labLoginErr.frame.height + heightSpace * 3
    }
    
    func hideCaptcha(){
        self.viewCaptcha.isHidden = true
        self.constraintCaptchaHeight.constant = 0
    }
    
    func showCaptcha( cpatchaTip: String, captcha: UIImage){
        viewCaptcha.isHidden = false
        constraintCaptchaHeight.constant = btnResendCaptcha.frame.maxY
        labCaptchaTip.text = cpatchaTip
        imgCaptcha.image = captcha
    }
    
    func showPasswordValidTip(message : String){
        labPasswordErr.text = message
        textPassword.showUnderline(message.count > 0)
        textPassword.setCorner(topCorner: true, bottomCorner: message.count == 0)
    }
    
    func showAccountValidtip(message : String){
        labAccountErr.text = message
        textAccount.showUnderline(message.count > 0)
        textAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
    }
    
    // MARK: API
    private func getCaptcha(){
        viewModel
            .getCaptchaImage()
            .subscribe(onSuccess: { image in })
            .disposed(by: disposeBag)
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnSignupPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueSignup, sender: nil)
    }
    
    @IBAction func btnLoginPressed(_ sender : UIButton){
        viewModel
            .loginFrom(isRememberMe : btnRememberMe.isSelected)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: {player in
                NavigationManagement.sharedInstance.goTo(productType: player.defaultProduct)
            }, onError: {error in
                self.handleError(error: error )
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnResetPasswordPressed(_ sender : UIButton){
        performSegue(withIdentifier: ResetPasswordViewController.segueIdentifier, sender: nil)
    }
    
    @IBAction func btnRememberMePressed(_ sender : UIButton){
        btnRememberMe.isSelected = !btnRememberMe.isSelected
    }
    
    @IBAction func btnResendCaptchaPressed(_ sender : UIButton){
        getCaptcha()
    }
    
    // MARK: PAGE ACTION
    @IBAction func backToLogin(segue: UIStoryboardSegue){
        if let vc = segue.source as? ResetPasswordStep3ViewController {
            if vc.changePasswordSuccess {
                toastView.show(statusTip: Localize.string("login_resetpassword_success"), img: UIImage(named: "Success"))
            }
        }
    }
}

extension LoginViewController{
    // MARK: PAGE PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navi = segue.destination as? UINavigationController,
           let signupVc = navi.viewControllers.first as? SignupLanguageViewController{
            signupVc.languageChangeHandler = {
                self.localize()
                self.viewModel.refresh()
            }
        }
    }
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
