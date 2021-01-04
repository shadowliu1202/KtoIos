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
    
    @IBOutlet private weak var inputAccount : InputTextField!
    @IBOutlet private weak var inputName : InputTextField!
    @IBOutlet private weak var inputPassword : InputTextField!
    @IBOutlet private weak var inputCsPassword : InputTextField!
    
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
        inputAccount.setCorner(topCorner: true, bottomCorner: true)
        inputName.setCorner(topCorner: true, bottomCorner: true)
        inputPassword.setCorner(topCorner: true, bottomCorner: false)
        inputPassword.confirmPassword = inputCsPassword
        inputPassword.isPassword()
        inputCsPassword.setCorner(topCorner: false, bottomCorner: true)
        inputCsPassword.isConfirmPassword()
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
        inputAccount.setEditingChangedHandler { (text) in
            self.viewModel.inputAccount(text)
        }
        inputName.setEditingChangedHandler { (text) in
            self.viewModel.inputName(text)
        }
        inputPassword.setEditingChangedHandler { (text) in
            self.viewModel.inputPassword(text)
        }
        inputCsPassword.setEditingChangedHandler { (text) in
            self.viewModel.inputConfirmPassword(text)
        }

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
        
        event.accountValid
            .subscribe(onNext: { status  in
                var message = ""
                if status == .errEmailFormat { message = Localize.string("error_email_format")}
                else if status == .errPhoneFormat { message = Localize.string("error_Mobile_format")}
                else if status == .empty && self.inputAccount.edited { message = Localize.string("field_must_fill")}
                self.labAccountTip.text = message
                self.inputAccount.showUnderline(message.count > 0)
                self.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
        
        event.nameValid
            .subscribe(onNext: { status in
                var message = ""
                if status == .errNameFormat { message = Localize.string("Step2_Name_format_error") }
                else if status == .empty && self.inputAccount.edited { message = Localize.string("field_must_fill")}
                self.labNameTip.text = message
                self.inputName.showUnderline(message.count > 0)
                self.inputName.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)

        event.passwordValid
            .subscribe(onNext: { status in
                var message = ""
                if (status == .errPasswordFormat) { message = Localize.string("Invalid_Username_password") }
                if (status == .errPasswordNotMatch) { message = Localize.string("Step2_password_not_match")}
                if status == .empty && self.inputPassword.edited { message = Localize.string("field_must_fill")}
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
                    self.inputAccount.setTitle(Localize.string("Mobile"))
                    self.inputAccount.setContent("")
                    self.inputAccount.setKeyboardType(.numberPad)
                    self.btnPhone.isSelected = true
                    self.btnEmail.isSelected = false
                    self.btnSubmit.setTitle(Localize.string("Step2_verify_mobile"), for: .normal)
                case .email:
                    self.inputAccount.setTitle(Localize.string("Email"))
                    self.inputAccount.setContent("")
                    self.inputAccount.setKeyboardType(.emailAddress)
                    self.btnPhone.isSelected = false
                    self.btnEmail.isSelected = true
                    self.btnSubmit.setTitle(Localize.string("Step2_verify_mail"), for: .normal)
                }
            }).disposed(by: disposeBag)
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
            .subscribe(onCompleted: {
                let segue : String = {
                    switch self.viewModel.currentAccountType(){
                    case .email: return self.segueEmail
                    case .phone: return self.seguePhone
                    }
                }()
                let para = ["account" : self.viewModel.currentAccount(),
                            "password" : self.viewModel.currentPassword()]
                self.performSegue(withIdentifier: segue, sender: para)
            }, onError: { error in
                let type = ErrorType(rawValue: (error as NSError).code) ?? .ApiUnknownException
                let title = type == .PlayerIpOverOtpDailyLimit ? Localize.string("tip_title_warm") : ""
                let message : String = {
                    switch type{
                    case .PlayerIpOverOtpDailyLimit: return Localize.string("email_otp_exeed_send_limit")
                    default: return String(format: Localize.string("UnknownError"), "\((error as NSError).code)")
                    }
                }()
                Alert.show(title, message, confirm: nil, cancel: nil)
            }).disposed(by: disposeBag)
    }
}
