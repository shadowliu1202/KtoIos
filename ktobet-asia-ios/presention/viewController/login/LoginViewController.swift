//
//  LoginViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/23.
//

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
    private let heightLoginError = CGFloat(80)
    private let heightCaptchaView = CGFloat(257)
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(LoginViewModel.self)!
    private var timerOverLoginLimit : KTOTimer = KTOTimer()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        defaulStyle()
        setViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let last = viewModel.lastOverLoginLimitDate,
           Date().timeIntervalSince1970 < last.timeIntervalSince1970{
            launchLoginLimitTimer(endDate: last)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopLoginLimitTimer()
    }
    
    deinit {}
    
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
        btnRememberMe.isSelected = viewModel.rememberAccount.count > 0 && viewModel.rememberPassword.count > 0
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
                    case .firstEmpty: return ""
                    case .empty: return Localize.string("common_field_must_fill")
                    case .valid: return ""
                    case .invalid: return ""
                    }
                }()
                self.labAccountErr.text = message
                self.textAccount.showUnderline(message.count > 0)
                self.textAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            })
            .disposed(by: disposeBag)
        
        event
            .passwordValid
            .subscribe(onNext: {status in
                let message : String = {
                    switch status{
                    case .firstEmpty: return ""
                    case .empty: return Localize.string("common_field_must_fill")
                    case .valid: return ""
                    case .invalid: return ""
                    }
                }()
                self.labPasswordErr.text = message
                self.textPassword.showUnderline(message.count > 0)
                self.textPassword.setCorner(topCorner: true, bottomCorner: message.count == 0)
            })
            .disposed(by: disposeBag)
        
        event
            .captchaImage
            .subscribe(onNext: { image in
                if image == nil {
                    self.hideCaptcha()
                } else {
                    self.showLoginErrTip()
                    self.showCaptcha()
                    self.imgCaptcha.image = image
                }
            })
            .disposed(by: disposeBag)
        
        event
            .dataValid
            .bind(to: btnLogin.rx.valid)
            .disposed(by: disposeBag)
    }
    
    // MARK: PRESENT
    private func showLoginErrTip(){
        viewLoginErr.isHidden = false
        constraintLoginErrorHeight.constant = heightLoginError
    }
    
    private func hideLoginErrTip(){
        viewLoginErr.isHidden = true
        constraintLoginErrorHeight.constant = 0
    }
    
    private func showCaptcha(){
        viewCaptcha.isHidden = false
        constraintCaptchaHeight.constant = heightCaptchaView
        labCaptchaTip.text = Localize.string("login_enter_captcha_to_prceed")
    }
    
    private func hideCaptcha(){
        viewCaptcha.isHidden = true
        constraintCaptchaHeight.constant = 0
    }
    
    // MARK: TIMER
    private func launchLoginLimitTimer(endDate : Date){
        
        guard Date().timeIntervalSince1970 < endDate.timeIntervalSince1970 else {
            return
        }
        labLoginErr.text = Localize.string("login_invalid_lockdown")
        showLoginErrTip()
        viewModel.overLoginLimit(isOver: true)
        timerOverLoginLimit
            .countDown(timeInterval: 1, endTime: endDate) { (idx, countDown, finish) in
                self.btnLogin.setTitle({
                    var title = Localize.string("common_login")
                    if countDown > 0{
                        title += "(\(countDown))"
                    }
                    return title
                }(), for: .normal)
                if finish{
                    self.viewModel.overLoginLimit(isOver: false)
                }
            }
    }
    
    private func stopLoginLimitTimer(){
        timerOverLoginLimit.stop()
    }
    
    // MARK: ERROR
    private func handleError(error : Any){
        if let loginFail = error as? LoginError, let status = loginFail.status{
            switch status {
            case .failed1to5:
                showLoginErrTip()
                labLoginErr.text = Localize.string("login_invalid_username_password")
            case .failed6to10:
                if imgCaptcha.image == nil { getCaptcha()}
                showLoginErrTip()
                labLoginErr.text = Localize.string("login_invalid_username_password_captcha")
            case .failedabove11:
                if imgCaptcha.image == nil { getCaptcha()}
                showLoginErrTip()
                labLoginErr.text = Localize.string("login_invalid_lockdown")
                viewModel.lastOverLoginLimitDate = Date.init(timeIntervalSince1970: Date().timeIntervalSince1970 + 60)
                launchLoginLimitTimer(endDate: viewModel.lastOverLoginLimitDate!)
            default: break
            }
        }
    }
    
    // MARK: API
    private func getCaptcha(){
        viewModel
            .getCaptchaImage()
            .subscribe(onSuccess: { image in
                self.viewModel.newCaptchaImage(image: image)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnSignupPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueSignup, sender: nil)
    }
    
    @IBAction func btnLoginPressed(_ sender : UIButton){
        viewModel
            .loginFrom()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: {result in
                self.viewModel.rememberAccount = self.btnRememberMe.isSelected ? result.account : ""
                self.viewModel.rememberPassword = self.btnRememberMe.isSelected ? result.password : ""
                self.goToLobby(result.player)
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
    private func goToLobby(_ player : Player){
        let storyboard = UIStoryboard(name: "Lobby", bundle: nil)
        if let initVc = storyboard.instantiateInitialViewController() as? UINavigationController,
           let lobby = initVc.viewControllers.first as? LobbyViewController {
            lobby.player = player
            UIApplication.shared.keyWindow?.rootViewController = initVc
        }
    }
}

extension LoginViewController{
    // MARK: PAGE PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
