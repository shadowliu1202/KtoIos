//
//  RegisterViewController.swift
//  KtoPra
//
//  Created by Partick Chen on 2020/10/21.
//

import UIKit
import RxSwift
import RxCocoa
import SharedBu
import Swinject

class SignupUserinfoViewController: LandingViewController {
    
    @IBOutlet private weak var naviItem : UINavigationItem!
    
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnSubmit: UIButton!
    @IBOutlet private weak var btnPhone: UIButton!
    @IBOutlet private weak var btnEmail: UIButton!
    
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var labRegistErrMessage : UILabel!
    @IBOutlet private weak var labAccountTip : UILabel!
    @IBOutlet private weak var labNameTip : UILabel!
    @IBOutlet private weak var labPasswordTip : UILabel!
    @IBOutlet private weak var labPasswordDesc : UILabel!
    @IBOutlet private weak var labOtpInvalid : UILabel!
    
    @IBOutlet private weak var inputMobile : InputText!
    @IBOutlet private weak var inputEmail : InputText!
    @IBOutlet private weak var inputName : InputText!
    @IBOutlet private weak var inputPassword : InputPassword!
    @IBOutlet private weak var inputCsPassword : InputConfirmPassword!
    
    @IBOutlet private weak var scrollView : UIScrollView!
    @IBOutlet private weak var viewButtons : UIView!
    @IBOutlet private weak var viewOtpInvalid : UIView!
    @IBOutlet private weak var viewRegistErrMessage : UIView!
    
    @IBOutlet private weak var constraintRegistErrMessageHeight : NSLayoutConstraint!
    var barButtonItems: [UIBarButtonItem] = []
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(delegate: self, disposeBag: disposeBag))
    
    private let errMsgHeight = CGFloat(56)
    private let segueLanguage = "BackToLanguageList"
    private let seguePhone = "GoToPhone"
    private let segueEmail = "GoToEmail"
    
    private var viewModel = DI.resolve(SignupUserInfoViewModel.self)!
    private var inputAccount : InputText {
        get{
            switch viewModel.currentAccountType() {
            case .email: return inputEmail
            case .phone: return inputMobile
            }
        }
    }
    private var countryCode : String {
        get {
            switch locale.cultureCode(){
            case "zh-cn": return "+86"
            default: return ""
            }
        }
    }
    private var disposeBag = DisposeBag()
    var locale : SupportLocale = SupportLocale.China()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .right, barButtonItems: padding, customService)
        localize()
        defaultStyle()
        setViewModel()
    }
    
    // MARK: METHOD
    func localize(){
        btnPhone.setTitle(Localize.string("common_mobile"), for: .normal)
        btnEmail.setTitle(Localize.string("common_email"), for: .normal)
        btnSubmit.setTitle(Localize.string("register_step2_verify_mobile"), for: .normal)
        inputEmail.setTitle(Localize.string("common_email"))
        inputMobile.setTitle(Localize.string("common_mobile"))
        inputName.setTitle(Localize.string("common_realname"))
        inputPassword.setTitle(Localize.string("common_password"))
        inputCsPassword.setTitle(Localize.string("common_password_2"))
        labTitle.text = Localize.string("register_step2_title_1")
        labDesc.text = Localize.string("register_step2_title_2")
        labPasswordDesc.text = Localize.string("common_password_tips_1")
    }
    
    func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        constraintRegistErrMessageHeight.constant = 0
        viewRegistErrMessage.isHidden = true
        viewRegistErrMessage.layer.cornerRadius = 8
        viewRegistErrMessage.layer.masksToBounds = true
        viewButtons.layer.cornerRadius = 8
        viewButtons.layer.masksToBounds = true
        labAccountTip.text = ""
        labNameTip.text = ""
        labPasswordTip.text = ""
        inputMobile.setCorner(topCorner: true, bottomCorner: true)
        inputMobile.setKeyboardType(.phonePad)
        inputMobile.setSubTitle(countryCode)
        inputEmail.setCorner(topCorner: true, bottomCorner: true)
        inputEmail.setKeyboardType(.emailAddress)
        inputName.setCorner(topCorner: true, bottomCorner: true)
        inputPassword.setCorner(topCorner: true, bottomCorner: false)
        inputPassword.confirmPassword = inputCsPassword
        inputCsPassword.inputPassword = inputPassword
        inputCsPassword.setCorner(topCorner: false, bottomCorner: true)
        btnSubmit.layer.cornerRadius = 8
        btnSubmit.layer.masksToBounds = true
        btnSubmit.backgroundColor = UIColor.red

        for button in [btnEmail, btnPhone]{
            let selectedColor = UIColor.backgroundTabsGray
            let unSelectedColor = UIColor.clear
            button?.setBackgroundImage(UIImage(color: selectedColor), for: .selected)
            button?.setBackgroundImage(UIImage(color: unSelectedColor), for: .normal)
            button?.layer.cornerRadius = 8
            button?.layer.masksToBounds = true
        }
    }
    
    func setViewModel(){

        viewModel.inputAccountType(.phone)
        viewModel.inputLocale(locale)
        
        (self.inputMobile.text <-> self.viewModel.relayMobile).disposed(by: self.disposeBag)
        (self.inputEmail.text <-> self.viewModel.relayEmail).disposed(by: self.disposeBag)
        (self.inputName.text <-> self.viewModel.relayName).disposed(by: self.disposeBag)
        (self.inputPassword.text <-> self.viewModel.relayPassword).disposed(by: self.disposeBag)
        (self.inputCsPassword.text <-> self.viewModel.relayConfirmPassword).disposed(by: self.disposeBag)

        let event = viewModel.event()
        event.otpValid
            .subscribe(onNext: { [weak self] status  in
                guard let `self` = self else { return }
                if status == .errEmailOtpInactive || status == .errSMSOtpInactive{
                    self.view.layoutIfNeeded()
                    let width = self.scrollView.bounds.size.width
                    let height = self.scrollView.contentSize.height - self.viewButtons.frame.maxY
                    self.viewOtpInvalid.frame = CGRect.init(x: 0, y: self.viewButtons.frame.maxY, width: width, height: height)
                    self.scrollView.addSubview(self.viewOtpInvalid)
                    self.labOtpInvalid.text = {
                        switch status {
                        case .errEmailOtpInactive: return Localize.string("register_step2_email_inactive")
                        case .errSMSOtpInactive: return Localize.string("register_step2_sms_inactive")
                        default: return ""
                        }
                    }()
                } else {
                    self.viewOtpInvalid.removeFromSuperview()
                }
            }).disposed(by: disposeBag)
        
        event.emailValid
            .subscribe(onNext: { [weak self] status in
                guard status != .doNothing else { return }
                var message = ""
                if status == .errEmailFormat {
                    message = Localize.string("common_error_email_format")
                } else if status == .empty {
                    message = Localize.string("common_field_must_fill")
                }
                self?.labAccountTip.text = message
                self?.inputAccount.showUnderline(message.count > 0)
                self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.mobileValid
            .subscribe(onNext: { [weak self] status in
                guard status != .doNothing else { return }
                var message = ""
                if status == .errPhoneFormat {
                    message = Localize.string("common_error_mobile_format")
                } else if status == .empty {
                    message = Localize.string("common_field_must_fill")
                }
                self?.labAccountTip.text = message
                self?.inputAccount.showUnderline(message.count > 0)
                self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.nameValid
            .subscribe(onNext: { [weak self] status in
                var message = ""
                if status == .errNameFormat {
                    message = Localize.string("register_step2_name_format_error")
                } else if status == .empty {
                    message = Localize.string("common_field_must_fill")
                }
                self?.labNameTip.text = message
                self?.inputName.showUnderline(message.count > 0)
                self?.inputName.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)

        event.passwordValid
            .subscribe(onNext: { [weak self] status in
                var message = ""
                if status == .errPasswordFormat {
                    message = Localize.string("common_field_format_incorrect")
                } else if status == .errPasswordNotMatch{
                    message = Localize.string("register_step2_password_not_match")
                } else if status == .empty {
                    message = Localize.string("common_field_must_fill")
                }
                self?.labPasswordTip.text = message
                self?.inputCsPassword.showUnderline(message.count > 0)
                self?.inputCsPassword.setCorner(topCorner: false, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.dataValid
            .bind(to: btnSubmit.rx.valid)
            .disposed(by: disposeBag)
        
        event.typeChange
            .subscribe(onNext: { [weak self] type in
                switch type {
                case .phone:
                    self?.inputEmail.isHidden = true
                    self?.inputMobile.isHidden = false
                    self?.btnPhone.isSelected = true
                    self?.btnEmail.isSelected = false
                    self?.btnSubmit.setTitle(Localize.string("register_step2_verify_mobile"), for: .normal)
                case .email:
                    self?.inputEmail.isHidden = false
                    self?.inputMobile.isHidden = true
                    self?.btnPhone.isSelected = false
                    self?.btnEmail.isSelected = true
                    self?.btnSubmit.setTitle(Localize.string("register_step2_verify_mail"), for: .normal)
                }
                self?.view.endEditing(true)
                self?.inputAccount.setContent("")
                self?.hideError()
            }).disposed(by: disposeBag)
    }
    
    func displayError(error: String) {
        self.viewRegistErrMessage.isHidden = false
        self.labRegistErrMessage.text = error
        self.constraintRegistErrMessageHeight.constant = errMsgHeight
    }
    
    func hideError() {
        self.viewRegistErrMessage.isHidden = true
        self.labRegistErrMessage.text = ""
        self.constraintRegistErrMessageHeight.constant = 0
    }
    
    override func abstracObserverUpdate() {
        self.observerCompulsoryUpdate()
    }
}

extension SignupUserinfoViewController{
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vcMail = segue.destination as? SignupEmailViewController,
           let userInfo = sender as? [String : String],
           let account = userInfo["account"],
           let password = userInfo["password"]{
            vcMail.account = account
            vcMail.password = password
        }
        if let vcPhone = segue.destination as? SignupPhoneViewController,
           let userInfo = sender as? [String : String],
           let account = userInfo["account"]{
            vcPhone.countryCode = countryCode
            vcPhone.phoneNumber = account
            vcPhone.locale = locale
        }
    }
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
    @IBAction func backToUserInfo(segue : UIStoryboardSegue){}
}

extension SignupUserinfoViewController{
    // MARK: BUTTON ACTION
    @IBAction func btnPhonePressed(_ sender : Any){
        viewModel.inputAccountType(.phone)
    }
    
    @IBAction func btnEmailPressed(_ sender : Any){
        viewModel.inputAccountType(.email)
    }
    
    @IBAction func btnBackPressed(_ sender : Any){
        let title = Localize.string("common_tip_title_unfinished")
        let message = Localize.string("common_tip_content_unfinished")
        Alert.show(title, message) {
            self.performSegue(withIdentifier: self.segueLanguage, sender: nil)
        } cancel: {}
    }
    
    @IBAction func btnSubmitPressed(_ sender : Any){
        
        viewModel.register()
            .subscribe(onSuccess: { [weak self] info in
                guard let `self` = self else { return }
                let segue : String = {
                    switch info.type {
                    case .email: return self.segueEmail
                    case .phone: return self.seguePhone
                    }
                }()
                let para = ["account" : info.account,
                            "password" : info.password]
                self.performSegue(withIdentifier: segue, sender: para)
            }, onError: { [weak self] error in
                let type = ErrorType(rawValue: (error as NSError).code) ?? .ApiUnknownException
                let message : String = {
                    switch type{
                    case .PlayerIpOverOtpDailyLimit: return Localize.string("common_email_otp_exeed_send_limit")
                    case .DBPlayerAlreadyExist:
                        switch self?.viewModel.currentAccountType(){
                        case .email: return Localize.string("common_error_email_verify")
                        case .phone: return Localize.string("common_error_phone_verify")
                        default: return ""
                        }
                    default: return String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)")
                    }
                }()
                
                self?.displayError(error: message)
            }).disposed(by: disposeBag)
    }
}

extension SignupUserinfoViewController: BarButtonItemable { }

extension SignupUserinfoViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}
