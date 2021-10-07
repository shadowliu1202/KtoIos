import UIKit
import RxSwift

class ResetPasswordStep2ViewController: UIViewController {
    static let segueIdentifier = "toStep2Segue"
    
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var labTip : UILabel!
    @IBOutlet private weak var labErrTip : UILabel!
    @IBOutlet private weak var viewErrTip : UIView!
    @IBOutlet private weak var viewStatusTip : ToastView!
    @IBOutlet private weak var smsVerifyView : SMSVerifyCodeInputView!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnVerify: UIButton!
    @IBOutlet private weak var btnResend: UIButton!
    @IBOutlet private weak var constraintErrTipHeight : NSLayoutConstraint!
    @IBOutlet private weak var constraintErrTipBottom : NSLayoutConstraint!
    @IBOutlet private weak var constraintStatusTipBottom : NSLayoutConstraint!
    
    var viewModel: ResetPasswordViewModel!
    private let errTipHeight = CGFloat(44)
    private let errTipBottom = CGFloat(12)
    private var disposeBag = DisposeBag()
    private let resendTimer = CountDownTimer()
    private let step2CountDownTimer = CountDownTimer()
    private var overStep2TimeLimit = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        setResendTimer()
        setStep2Timer()
        setViewModel()
        viewStatusTip.show(statusTip: Localize.string("common_otp_send_success"), img: UIImage(named: "Success"))
        showPasscodeUncorrectTip(false)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            constraintStatusTipBottom.constant = keyboardHeight
        }
    }
    
    private func initialize() {
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        switch viewModel.currentAccountType() {
        case .email:
            labDesc.text = Localize.string("login_resetpassword_step2_verify_by_email_title")
            labTip.text = Localize.string("common_otp_sent_content") + "\n" + viewModel.getAccount()
        case .phone:
            labDesc.text = Localize.string("login_resetpassword_step2_verify_by_phone_title")
            labTip.text = Localize.string("common_otp_sent_content") + "\n" + "+\(viewModel.locale.cellPhoneNumberFormat().areaCode()) " + viewModel.getAccount()
        }
        
        btnVerify.layer.cornerRadius = 8
        btnVerify.layer.masksToBounds = true
        btnVerify.setBackgroundImage(UIImage(color: UIColor.red), for: .disabled)
        btnVerify.setBackgroundImage(UIImage(color: UIColor.redForDark50230), for: .normal)
    }
    
    private func setViewModel() {
        
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
    
    private func showPasscodeUncorrectTip(_ show: Bool){
        constraintErrTipHeight.constant = show ? errTipHeight : 0
        constraintErrTipBottom.constant = show ? errTipBottom : 0
        viewErrTip.isHidden = !show
    }
    
    private func setResendTimer() {
        resendTimer.start(timeInterval: 1, duration: Setting.resendOtpCountDownSecond) {[weak self] (index, countDownSecond, finish) in
            if countDownSecond != 0 {
                let mm = countDownSecond / 60
                let ss = countDownSecond % 60
                let text = String(format: Localize.string("common_otp_resend_tips"), String(format: "%02d:%02d", mm, ss)) + Localize.string("common_resendotp")
                let attributedString = NSMutableAttributedString(string: text, attributes: [
                    .font: UIFont(name: "PingFangSC-Regular", size: 14.0)!,
                    .foregroundColor: UIColor.textPrimaryDustyGray,
                    .kern: 0.0
                ])
                
                attributedString.addAttribute(.foregroundColor, value: UIColor.redForDark502, range: NSRange(location: text.count - 4, length: 4))
                self?.btnResend.setAttributedTitle(attributedString, for: .normal)
                self?.btnResend.isEnabled = false
            } else {
                let text = String(format: Localize.string("common_otp_resend_tips"), String(format: "%02d:%02d", 00, 00)) + Localize.string("common_resendotp")
                let attributedString = NSMutableAttributedString(string: text, attributes: [
                    .font: UIFont(name: "PingFangSC-Regular", size: 14.0)!,
                    .foregroundColor: UIColor.textPrimaryDustyGray,
                    .kern: 0.0
                ])
                attributedString.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: text.count - 4, length: 4))
                self?.btnResend.setAttributedTitle(attributedString, for: .normal)
                self?.btnResend.isEnabled = true
            }
        }
    }
    
    private func setStep2Timer() {
        step2CountDownTimer.start(timeInterval: 1, duration: ResetPasswordViewModel.resetPasswordStep2CountDownSecond) {[weak self] (index, countDownSecond, finish) in
            if countDownSecond == 0 {
                self?.overStep2TimeLimit = true
            }
        }
    }
    
    private func handleError(_ error: Error) {
        let type = ErrorType(rawValue: (error as NSError).code)
        switch type {
        case .PlayerOtpCheckError:
            showPasscodeUncorrectTip(true)
        case .PlayerOverOtpRetryLimit:
            showErrorPage()
        case .PlayerIpOverOtpDailyLimit:
            alertExccedResendLimit()
        default:
            viewStatusTip.show(statusTip: Localize.string("common_unknownerror"), img: UIImage(named: "Failed"))
        }
    }
    
    private func showErrorPage() {
        performSegue(withIdentifier: SignupRegistFailViewController.segueIdentifier, sender: nil)
    }
    
    private func alertExccedResendLimit() {
        let title = Localize.string("common_tip_title_warm")
        let message = viewModel.currentAccountType() == .phone ? Localize.string("common_sms_otp_exeed_send_limit") : Localize.string("common_sms_otp_exeed_send_limit")
        Alert.show(title, message, confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }, cancel: nil)
    }
    
    @IBAction func btnResendPressed(_ sender: UIButton){
        if overStep2TimeLimit {
            performSegue(withIdentifier: SignupRegistFailViewController.segueIdentifier, sender: nil)
            return
        }
        
        viewModel.resendOtp().subscribe {
            self.viewStatusTip.show(statusTip: Localize.string("common_success"), img: UIImage(named: "Success"))
            self.setResendTimer()
        } onError: { (error) in
            self.setResendTimer()
            self.handleError(error)
        }.disposed(by: disposeBag)
    }
        
    @IBAction func btnVerifyPressed(_ sender: UIButton){
        if overStep2TimeLimit {
            performSegue(withIdentifier: SignupRegistFailViewController.segueIdentifier, sender: nil)
            return
        }
        
        viewModel.verifyResetOtp().subscribe {
            self.viewModel.otpRetryCount = 0
            self.performSegue(withIdentifier: ResetPasswordStep3ViewController.segueIdentifier, sender: nil)
        } onError: { (error) in
            self.handleError(error)
        }.disposed(by: disposeBag)
    }
    
    @IBAction func btnBackPressed(_ sender: UIButton){
        let title = Localize.string("common_confirm_cancel_operation")
        let message = Localize.string("login_resetpassword_cancel_content")
        Alert.show(title, message) {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } cancel: {}
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SignupRegistFailViewController.segueIdentifier {
            if let dest = segue.destination as? SignupRegistFailViewController {
                dest.failedType = .resetPassword
            }
        }
    }
}

