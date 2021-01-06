//
//  RegisterViewController.swift
//  KtoPra
//
//  Created by Partick Chen on 2020/10/21.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu
import Swinject

class SignupUserinfoViewController: UIViewController {
    
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
    
    private let errMsgHeight = 56
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
    private var disposeBag = DisposeBag()
    var locale : SupportLocale = SupportLocale.China()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        defaultStyle()
        setViewModel()
    }
    
    // MARK: METHOD
    func localize(){
        btnPhone.setTitle(Localize.string("Mobile"), for: .normal)
        btnEmail.setTitle(Localize.string("Email"), for: .normal)
        btnSubmit.setTitle(Localize.string("Step2_verify_mobile"), for: .normal)
        inputEmail.setTitle(Localize.string("Email"))
        inputMobile.setTitle(Localize.string("Mobile"))
        inputName.setTitle(Localize.string("RealName"))
        inputPassword.setTitle(Localize.string("Password"))
        inputCsPassword.setTitle(Localize.string("Password_2"))
        labTitle.text = Localize.string("Step2_Title_1")
        labDesc.text = Localize.string("Step2_Title_2")
        labPasswordDesc.text = Localize.string("Password_Tips_1")
    }
    
    func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        constraintRegistErrMessageHeight.constant = 0
        viewRegistErrMessage.isHidden = true
        viewButtons.layer.cornerRadius = 8
        viewButtons.layer.masksToBounds = true
        labAccountTip.text = ""
        labNameTip.text = ""
        labPasswordTip.text = ""
        inputMobile.setCorner(topCorner: true, bottomCorner: true)
        inputMobile.setKeyboardType(.phonePad)
        inputMobile.setSubTitle({
            switch locale.cultureCode(){
            case "zh-cn": return "+86"
            default: return ""
            }
        }())
        inputEmail.setCorner(topCorner: true, bottomCorner: true)
        inputEmail.setKeyboardType(.emailAddress)
        inputName.setCorner(topCorner: true, bottomCorner: true)
        inputPassword.setCorner(topCorner: true, bottomCorner: false)
        inputPassword.confirmPassword = inputCsPassword
        inputCsPassword.setCorner(topCorner: false, bottomCorner: true)
        btnSubmit.layer.cornerRadius = 8
        btnSubmit.layer.masksToBounds = true

        for button in [btnEmail, btnPhone]{
            let selectedColor = UIColor.init(rgb: 0x636366)
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
            .subscribe(onNext: { status  in
                if status == .errEmailOtpInactive || status == .errSMSOtpInactive{
                    self.view.layoutIfNeeded()
                    let width = self.scrollView.bounds.size.width
                    let height = self.btnSubmit.frame.maxY - self.viewButtons.frame.maxY
                    self.viewOtpInvalid.frame = CGRect.init(x: 0, y: self.viewButtons.frame.maxY, width: width, height: height)
                    self.scrollView.addSubview(self.viewOtpInvalid)
                    self.labOtpInvalid.text = {
                        switch status {
                        case .errEmailOtpInactive: return Localize.string("step2_email_Inactive")
                        case .errSMSOtpInactive: return Localize.string("step2_sms_Inactive")
                        default: return ""
                        }
                    }()
                } else {
                    self.viewOtpInvalid.removeFromSuperview()
                }
            }).disposed(by: disposeBag)
        
        event.emailValid
            .subscribe(onNext: {status in
                var message = ""
                if status == .errEmailFormat {
                    message = Localize.string("error_email_format")
                } else if status == .empty {
                    message = Localize.string("field_must_fill")
                }
                self.labAccountTip.text = message
                self.inputAccount.showUnderline(message.count > 0)
                self.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.mobileValid
            .subscribe(onNext: { status in
                var message = ""
                if status == .errPhoneFormat {
                    message = Localize.string("error_Mobile_format")
                } else if status == .empty {
                    message = Localize.string("field_must_fill")
                }
                self.labAccountTip.text = message
                self.inputAccount.showUnderline(message.count > 0)
                self.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.nameValid
            .subscribe(onNext: { status in
                var message = ""
                if status == .errNameFormat {
                    message = Localize.string("Step2_Name_format_error")
                } else if status == .empty {
                    message = Localize.string("field_must_fill")
                }
                self.labNameTip.text = message
                self.inputName.showUnderline(message.count > 0)
                self.inputName.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)

        event.passwordValid
            .subscribe(onNext: { status in
                var message = ""
                if status == .errPasswordFormat {
                    message = Localize.string("Invalid_Username_password")
                } else if status == .errPasswordNotMatch{
                    message = Localize.string("Step2_password_not_match")
                } else if status == .empty {
                    message = Localize.string("field_must_fill")
                }
                self.labPasswordTip.text = message
                self.inputCsPassword.showUnderline(message.count > 0)
                self.inputCsPassword.setCorner(topCorner: false, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.dataValid
            .bind(to: btnSubmit.rx.valid)
            .disposed(by: disposeBag)
        
        event.typeChange
            .subscribe(onNext: {type in
                switch type {
                case .phone:
                    self.inputEmail.isHidden = true
                    self.inputMobile.isHidden = false
                    self.btnPhone.isSelected = true
                    self.btnEmail.isSelected = false
                    self.btnSubmit.setTitle(Localize.string("Step2_verify_mobile"), for: .normal)
                case .email:
                    self.inputEmail.isHidden = false
                    self.inputMobile.isHidden = true
                    self.btnPhone.isSelected = false
                    self.btnEmail.isSelected = true
                    self.btnSubmit.setTitle(Localize.string("Step2_verify_mail"), for: .normal)
                }
                self.inputAccount.setContent("")
                self.inputAccount.showKeyboard()
                self.hideError()
            }).disposed(by: disposeBag)
    }
    
    func displayError(error: String) {
        self.viewRegistErrMessage.isHidden = false
        self.labRegistErrMessage.text = error
        self.constraintRegistErrMessageHeight.constant = 44
    }
    
    func hideError() {
        self.viewRegistErrMessage.isHidden = true
        self.labRegistErrMessage.text = ""
        self.constraintRegistErrMessageHeight.constant = 0
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
        let title = Localize.string("tip_title_unfinished")
        let message = Localize.string("tip_content_unfinished")
        Alert.show(title, message) {
            self.performSegue(withIdentifier: self.segueLanguage, sender: nil)
        } cancel: {}
    }
    
    @IBAction func btnSubmitPressed(_ sender : Any){
        
        viewModel.register()
            .subscribe(onSuccess: { info in
                let segue : String = {
                    switch info.type {
                    case .email: return self.segueEmail
                    case .phone: return self.seguePhone
                    }
                }()
                let para = ["account" : info.account,
                            "password" : info.password]
                self.performSegue(withIdentifier: segue, sender: para)
            }, onError: {error in
                let type = ErrorType(rawValue: (error as NSError).code) ?? .ApiUnknownException
                let message : String = {
                    switch type{
                    case .PlayerIpOverOtpDailyLimit: return Localize.string("email_otp_exeed_send_limit")
                    case .DBPlayerAlreadyExist:
                        switch self.viewModel.currentAccountType(){
                        case .email: return Localize.string("step2_email_verify_fail")
                        case .phone: return Localize.string("step2_phone_verify_fail")
                        }
                    default: return String(format: Localize.string("UnknownError"), "\((error as NSError).code)")
                    }
                }()
                
                self.displayError(error: message)
            }).disposed(by: disposeBag)
    }
}
