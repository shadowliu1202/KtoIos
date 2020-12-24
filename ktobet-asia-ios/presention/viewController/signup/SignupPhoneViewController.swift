//
//  Register3ViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/29.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu

class SignupPhoneViewController: UIViewController {

    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var labTip : UILabel!
    @IBOutlet private weak var labErrTip : UILabel!
    @IBOutlet private weak var labStatusTip : UILabel!
    @IBOutlet private weak var viewErrTip : UIView!
    @IBOutlet private weak var viewStatusTip : UIView!
    @IBOutlet private weak var imgStatusTip : UIImageView!
    @IBOutlet private weak var textCode1: SMSCodeTextField!
    @IBOutlet private weak var textCode2: SMSCodeTextField!
    @IBOutlet private weak var textCode3: SMSCodeTextField!
    @IBOutlet private weak var textCode4: SMSCodeTextField!
    @IBOutlet private weak var textCode5: SMSCodeTextField!
    @IBOutlet private weak var textCode6: SMSCodeTextField!
    @IBOutlet private weak var btnCode1 : UIButton!
    @IBOutlet private weak var btnCode2 : UIButton!
    @IBOutlet private weak var btnCode3 : UIButton!
    @IBOutlet private weak var btnCode4 : UIButton!
    @IBOutlet private weak var btnCode5 : UIButton!
    @IBOutlet private weak var btnCode6 : UIButton!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnVerify: UIButton!
    @IBOutlet private weak var btnResend: UIButton!
    @IBOutlet private weak var constraintErrTipHeight : NSLayoutConstraint!
    @IBOutlet private weak var constraintErrTipBottom : NSLayoutConstraint!
    
    private let segueUserInfo = "BackToUserInfo"
    private let segueFail = "GoToFail"
    private let errTipHeight = CGFloat(44)
    private let errTipBottom = CGFloat(12)
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(SignupPhoneViewModel.self)!
    private var timer : Timer?
    private var count = 0
    var phoneNumber = ""
    var locale : SupportLocale = SupportLocale.China()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
        localize()
        setViewModel()
        launchTimer()
        showStatusTip()
    }
    
    // MARK: METHOD
    private func localize(){
        labStatusTip.text = Localize.string("Otp_Send_Success")
        labTitle.text = Localize.string("Step3_Title_1")
        labDesc.text = Localize.string("step3_verify_by_phone_title")
        labTip.text = Localize.string("otp_sent_content") + "\n" + phoneNumber
        labErrTip.text = Localize.string("Step3_incorrect_otp")
        btnVerify.setTitle(Localize.string("Verify") , for: .normal)
        btnResend.setAttributedTitle({
            let text = NSMutableAttributedString()
            let attr1 : NSAttributedString = {
                let color = UIColor(red: 155.0/255.0, green: 155.0/255.0, blue: 155.0/255.0, alpha: 1.0)
                let resendTip = Localize.string("Otp_Resend_Tips")
                let time = "00:00"
                let text = String(format: resendTip, time)
                return NSAttributedString.init(string: text, attributes: [.foregroundColor : color])
            }()
            let attr2 : NSAttributedString = {
                let color = UIColor.init(red: 242.0/255.0, green: 0.0, blue: 0.0, alpha: 0.5)
                let resend = Localize.string("ResendOtp")
                return NSAttributedString.init(string: resend, attributes: [.foregroundColor : color])
            }()
            text.append(attr1)
            text.append(attr2)
            return text
        }(), for: .normal)
    }
    
    private func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        
        viewErrTip.layer.cornerRadius = 8
        viewErrTip.layer.masksToBounds = true
        viewStatusTip.layer.cornerRadius = 8
        viewStatusTip.layer.masksToBounds = true
        showPasscodeUncorrectTip(false)
        for textField in [textCode1, textCode2, textCode3, textCode4, textCode5, textCode6]{
            textField?.layer.cornerRadius = 6
            textField?.layer.masksToBounds = true
            textField?.myDelegate = self
        }
        btnVerify.isEnabled = false
        btnVerify.layer.cornerRadius = 8
        btnVerify.layer.masksToBounds = true
        btnVerify.setBackgroundImage(UIImage(color: UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.3)), for: .disabled)
        btnVerify.setBackgroundImage(UIImage(color: UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)), for: .normal)
        btnResend.isEnabled = false
    }
    
    private func setViewModel(){
        (textCode1.rx.text.orEmpty <-> viewModel.code1).disposed(by: disposeBag)
        (textCode2.rx.text.orEmpty <-> viewModel.code2).disposed(by: disposeBag)
        (textCode3.rx.text.orEmpty <-> viewModel.code3).disposed(by: disposeBag)
        (textCode4.rx.text.orEmpty <-> viewModel.code4).disposed(by: disposeBag)
        (textCode5.rx.text.orEmpty <-> viewModel.code5).disposed(by: disposeBag)
        (textCode6.rx.text.orEmpty <-> viewModel.code6).disposed(by: disposeBag)
        
        viewModel
            .checkCodeValid()
            .bind(to: self.btnVerify.rx.valid)
            .disposed(by: disposeBag)
    }
    
    private func launchTimer(){
        count = 180
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {timer in
            self.count -= 1
            let enable : Bool = {
                if self.count > 0 { return false }
                else { return true }
            }()
            if enable {
                self.timer?.invalidate()
            }
            self.btnResend.setAttributedTitle({
                let text = NSMutableAttributedString()
                let attr1 : NSAttributedString = {
                    let color = UIColor(red: 155.0/255.0, green: 155.0/255.0, blue: 155.0/255.0, alpha: 1.0)
                    let resendTip = Localize.string("Otp_Resend_Tips")
                    let time : String = {
                        let mm = self.count / 60
                        let ss = self.count % 60
                        return String(format: "%02d:%02d", mm, ss)
                    }()
                    let text = String(format: resendTip, time)
                    return NSAttributedString.init(string: text, attributes: [.foregroundColor : color])
                }()
                let attr2 : NSAttributedString = {
                    let enableColor = UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
                    let disableColor = UIColor(red: 242.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.5)
                    let resend = Localize.string("ResendOtp")
                    return NSAttributedString.init(string: resend, attributes: [.foregroundColor : (enable ? enableColor : disableColor)])
                }()
                text.append(attr1)
                text.append(attr2)
                return text
            }(), for: .normal)
            self.btnResend.isEnabled = enable
        })
        timer?.fire()
    }
    
    private func handleError(_ error: Error) {
        let type = ErrorType(rawValue: (error as NSError).code)
        switch type {
        case .PlayerOverOtpRetryLimit:
            performSegue(withIdentifier: self.segueFail, sender: nil)
        case .PlayerIpOverOtpDailyLimit:
            let title = Localize.string("tip_title_warm")
            let message = Localize.string("sms_otp_exeed_send_limit")
            Alert.show(title, message, confirm: {
                self.navigationController?.popToRootViewController(animated: true)
            }, cancel: nil)
        case .PlayerOtpCheckError:
            showPasscodeUncorrectTip(true)
        default:
            handleUnknownError(error)
        }
    }
    
    private func showPasscodeUncorrectTip(_ show : Bool){
        constraintErrTipHeight.constant = show ? errTipHeight : 0
        constraintErrTipBottom.constant = show ? errTipBottom : 0
        viewErrTip.isHidden = !show
    }
    
    private func showStatusTip(){
        viewStatusTip.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.viewStatusTip.isHidden = true
        }
    }
    
    // MARK: BUTTON EVENT
    @IBAction func btnCodePressed(_ sender: UIButton){
        switch sender {
        case btnCode1: textCode1.becomeFirstResponder()
        case btnCode2: textCode2.becomeFirstResponder()
        case btnCode3: textCode3.becomeFirstResponder()
        case btnCode4: textCode4.becomeFirstResponder()
        case btnCode5: textCode5.becomeFirstResponder()
        case btnCode6: textCode6.becomeFirstResponder()
        default: break
        }
    }
    
    
    @IBAction func btnBackPressed(_ sender : Any){
        let title = Localize.string("tip_title_unfinished")
        let message = Localize.string("tip_content_unfinished")
        Alert.show(title, message) {
            self.navigationController?.popToRootViewController(animated: true)
        } cancel: {}
    }
    
    @IBAction func btnResendPressed(_ sender : Any){
        viewModel
            .resendRegisterOtp()
            .subscribe(onCompleted: {
                self.launchTimer()
                self.showStatusTip()
            }, onError: {error in
                self.handleError(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnVerifyPressed(_ sender : Any){
        viewModel
            .otpVerify()
            .subscribe(onSuccess: {player in
                self.goToLobby(player)
            }, onError: {error in
                self.handleError(error)
            }).disposed(by: disposeBag)
    }
    
    // MARK: TEXTFIELD EVENT
    @IBAction func textEditingChaged(_ sender : UITextField){
        if (sender.text?.count ?? 0) >= 1 {
            sender.text = {
                let text = sender.text!
                let index = text.index(text.endIndex, offsetBy: -1)
                return String(text[index])
            }()
            switch  sender {
            case textCode1: textCode2.becomeFirstResponder()
            case textCode2: textCode3.becomeFirstResponder()
            case textCode3: textCode4.becomeFirstResponder()
            case textCode4: textCode5.becomeFirstResponder()
            case textCode5: textCode6.becomeFirstResponder()
            case textCode6: textCode6.resignFirstResponder()
            default: break
            }
        }
    }
    
    // MARK: PAGE ACTION
    private func goToLobby(_ player : Player){
        let storyboard = UIStoryboard(name: "Lobby", bundle: nil)
        if let initVc = storyboard.instantiateInitialViewController() as? UINavigationController,
           let lobby = initVc.viewControllers.first as? LobbyViewController {
            lobby.player = player
            UIApplication.shared.keyWindow?.rootViewController = initVc
        }
    }
}

extension SignupPhoneViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}

extension SignupPhoneViewController : SMSCodeTextFieldDelegate{
    func textFieldDidDelete(_ sender: SMSCodeTextField) {
        if (sender.text?.count ?? 0) == 0{
            switch sender {
            case textCode6: textCode5.becomeFirstResponder()
            case textCode5: textCode4.becomeFirstResponder()
            case textCode4: textCode3.becomeFirstResponder()
            case textCode3: textCode2.becomeFirstResponder()
            case textCode2: textCode1.becomeFirstResponder()
            default: break
            }
        }
    }
}
