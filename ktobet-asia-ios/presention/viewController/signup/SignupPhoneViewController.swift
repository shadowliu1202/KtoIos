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
    @IBOutlet private weak var smsVerifyView : SMSVerifyCodeInputView!
    @IBOutlet private weak var btnBack : UIBarButtonItem!
    @IBOutlet private weak var btnVerify : UIButton!
    @IBOutlet private weak var btnResend : UIButton!
    @IBOutlet private weak var constraintErrTipHeight : NSLayoutConstraint!
    @IBOutlet private weak var constraintErrTipBottom : NSLayoutConstraint!
    
    private let segueUserInfo = "BackToUserInfo"
    private let segueFail = "GoToFail"
    private let errTipHeight = CGFloat(44)
    private let errTipBottom = CGFloat(12)
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(SignupPhoneViewModel.self)!
    private var timerResend = KTOTimer()
    private var timerOtpExpire = KTOTimer()
    private var countVerifyFail = 0
    private var countResend = 0
    private var otpExpire = false
    var countryCode = ""
    var phoneNumber = ""
    var locale : SupportLocale = SupportLocale.China()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
        localize()
        setViewModel()
        showStatusTip()
        resendTimer(launch: true)
        otpExpireTimer()
    }
    
    deinit {
        timerOtpExpire.stop()
    }
    
    // MARK: METHOD
    private func localize(){
        labStatusTip.text = Localize.string("common_otp_send_success")
        labTitle.text = Localize.string("register_step3_title_1")
        labDesc.text = Localize.string("register_step3_verify_by_phone_title")
        labTip.text = Localize.string("common_otp_sent_content") + "\n" + [countryCode, phoneNumber].joined(separator: " ")
        labErrTip.text = Localize.string("register_step3_incorrect_otp")
        btnVerify.setTitle(Localize.string("common_verify") , for: .normal)
    }
    
    private func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        viewErrTip.layer.cornerRadius = 8
        viewErrTip.layer.masksToBounds = true
        viewStatusTip.layer.cornerRadius = 8
        viewStatusTip.layer.masksToBounds = true
        showPasscodeUncorrectTip(false)
        btnVerify.isEnabled = false
        btnVerify.layer.cornerRadius = 8
        btnVerify.layer.masksToBounds = true
        btnVerify.setBackgroundImage(UIImage(color: UIColor.redForDark502), for: .disabled)
        btnVerify.setBackgroundImage(UIImage(color: UIColor.red), for: .normal)
        btnResend.isEnabled = false
    }
    
    private func setViewModel(){
        
        (smsVerifyView.code1.rx.text.orEmpty <-> viewModel.code1).disposed(by: disposeBag)
        (smsVerifyView.code2.rx.text.orEmpty <-> viewModel.code2).disposed(by: disposeBag)
        (smsVerifyView.code3.rx.text.orEmpty <-> viewModel.code3).disposed(by: disposeBag)
        (smsVerifyView.code4.rx.text.orEmpty <-> viewModel.code4).disposed(by: disposeBag)
        (smsVerifyView.code5.rx.text.orEmpty <-> viewModel.code5).disposed(by: disposeBag)
        (smsVerifyView.code6.rx.text.orEmpty <-> viewModel.code6).disposed(by: disposeBag)
        
        viewModel
            .checkCodeValid()
            .bind(to: self.btnVerify.rx.valid)
            .disposed(by: disposeBag)
    }
    
    private func setResendButton(_ seconds : Int){
        let enable = seconds == 0
        self.btnResend.setAttributedTitle({
            let text = NSMutableAttributedString()
            let attr1 : NSAttributedString = {
                let color = UIColor.textPrimaryDustyGray
                let resendTip = Localize.string("common_otp_resend_tips")
                let time : String = {
                    let mm = seconds / 60
                    let ss = seconds % 60
                    return String(format: "%02d:%02d", mm, ss)
                }()
                let text = String(format: resendTip, time)
                return NSAttributedString.init(string: text, attributes: [.foregroundColor : color])
            }()
            let attr2 : NSAttributedString = {
                let enableColor = UIColor.red
                let disableColor = UIColor.redForDark502
                let resend = Localize.string("common_resendotp")
                return NSAttributedString.init(string: resend, attributes: [.foregroundColor : (enable ? enableColor : disableColor)])
            }()
            text.append(attr1)
            text.append(attr2)
            return text
        }(), for: .normal)
        self.btnResend.isEnabled = enable
    }
    
    // MARK: TIMER
    private func resendTimer(launch : Bool){
        if launch{
            timerResend
                .countDown(timeInterval: 1, duration: 180, block: {(index, second, finish) in
                    self.setResendButton(second)
                })
        } else {
            timerResend
                .stop()
        }
    }
    
    private func otpExpireTimer(){
        timerOtpExpire
            .countDown(timeInterval: 1, duration: 600, block: {(index, second, finish) in
                if finish { self.otpExpire = true }
            })
    }
    
    // MARK: PRESENT
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
    
    private func handleError(_ error: Error) {
        let type = ErrorType(rawValue: (error as NSError).code)
        switch type {
        case .PlayerIdOverOtpLimit, .PlayerIpOverOtpDailyLimit:
            let title = Localize.string("common_tip_title_warm")
            let message = Localize.string("common_sms_otp_exeed_send_limit")
            Alert
                .show(title, message, confirm: {
                    self.navigationController?.popToRootViewController(animated: true)
                }, cancel: nil)
            break
        case .PlayerOverOtpRetryLimit, .PlayerResentOtpOverTenTimes:
            let title = Localize.string("common_tip_title_warm")
            let message = Localize.string("common_sms_otp_exeed_send_limit")
            Alert
                .show(title, message, confirm: {
                    self.navigationController?.popToRootViewController(animated: true)
                }, cancel: nil)
            break
        case .PlayerOtpCheckError:
            countVerifyFail += 1
            showPasscodeUncorrectTip(true)
            if countVerifyFail > 5{
                performSegue(withIdentifier: self.segueFail, sender: nil)
            }
            break
        default:
            performSegue(withIdentifier: self.segueFail, sender: nil)
        }
    }
    
    // MARK: BUTTON EVENT
    @IBAction func btnBackPressed(_ sender : Any){
        let title = Localize.string("common_tip_title_unfinished")
        let message = Localize.string("common_tip_content_unfinished")
        Alert.show(title, message) {
            self.navigationController?.popToRootViewController(animated: true)
        } cancel: {}
    }
    
    @IBAction func btnResendPressed(_ sender : Any){
        
        guard countResend < 6 else {
            performSegue(withIdentifier: self.segueFail, sender: nil)
            return
        }
        viewModel
            .resendRegisterOtp()
            .subscribe(onCompleted: {
                self.resendTimer(launch: true)
                self.countResend += 1
                self.showStatusTip()
            }, onError: {error in
                self.handleError(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnVerifyPressed(_ sender : Any){
        guard otpExpire == false else{
            performSegue(withIdentifier: self.segueFail, sender: nil)
            return
        }
        viewModel
            .otpVerify()
            .subscribe(onSuccess: {player in
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
            }, onError: {error in
                self.handleError(error)
            }).disposed(by: disposeBag)
    }
}

extension SignupPhoneViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}

