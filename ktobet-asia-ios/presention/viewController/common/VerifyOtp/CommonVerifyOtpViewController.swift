import UIKit
import RxSwift
import SharedBu

class CommonVerifyOtpViewController: APPViewController {
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var labTitle: UILabel!
    @IBOutlet private weak var labDesc: UILabel!
    @IBOutlet private weak var labTip: UILabel!
    @IBOutlet private weak var labJunkTip: UILabel!
    @IBOutlet private weak var labErrTip: UILabel!
    @IBOutlet private weak var viewErrTip: UIView!
    @IBOutlet private weak var viewStatusTip: ToastView!
    @IBOutlet private weak var smsVerifyView: SMSVerifyCodeInputView!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnVerify: UIButton!
    @IBOutlet private weak var btnResend: UIButton!
    @IBOutlet private weak var constraintErrTipHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintErrTipBottom: NSLayoutConstraint!
    @IBOutlet private weak var constraintStatusTipBottom: NSLayoutConstraint!

    var delegate: OtpViewControllerProtocol!
    var barButtonItems: [UIBarButtonItem] = []

    private let errTipHeight = CGFloat(44)
    private let errTipBottom = CGFloat(12)
    private var disposeBag = DisposeBag()
    private let resendTimer = CountDownTimer()
    private let step2CountDownTimer = CountDownTimer()
    private var overStep2TimeLimit = false
    private var otpRetryCount = 0
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(delegate: self, disposeBag: disposeBag))
    private lazy var validator = OtpValidator(accountPatternGenerator: accountPatternGenerator)
    private var accountPatternGenerator = DI.resolve(AccountPatternGenerator.self)!
    private var code1 = BehaviorRelay(value: "")
    private var code2 = BehaviorRelay(value: "")
    private var code3 = BehaviorRelay(value: "")
    private var code4 = BehaviorRelay(value: "")
    private var code5 = BehaviorRelay(value: "")
    private var code6 = BehaviorRelay(value: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        if !delegate.commonVerifyOtpArgs.isHiddenCSBarItem { self.bind(position: .right, barButtonItems: padding, customService) }
        initialize()
        bindingViews()
        setResendTimer()
        setStep2Timer()
        viewStatusTip.show(on: self.view, statusTip: Localize.string("common_otp_send_success"), img: UIImage(named: "Success"))
        showPasscodeUncorrectTip(false)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    @objc func keyboardWillShow(_ notification: RxSwift.Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            constraintStatusTipBottom.constant = keyboardHeight
        }
    }

    private func initialize() {
        if !delegate.commonVerifyOtpArgs.isHiddenBarTitle { naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)")) }
        labTitle.text = delegate.commonVerifyOtpArgs.title
        labDesc.text = delegate.commonVerifyOtpArgs.description
        labTip.text = delegate.commonVerifyOtpArgs.identityTip
        labJunkTip.text = delegate.commonVerifyOtpArgs.junkTip
        btnVerify.layer.cornerRadius = 8
        btnVerify.layer.masksToBounds = true
        btnVerify.setBackgroundImage(UIImage(color: UIColor.red), for: .disabled)
        btnVerify.setBackgroundImage(UIImage(color: UIColor.redForDark50230), for: .normal)
    }

    func bindingViews() {
        (smsVerifyView.code1.rx.text.orEmpty <-> code1).disposed(by: disposeBag)
        (smsVerifyView.code2.rx.text.orEmpty <-> code2).disposed(by: disposeBag)
        (smsVerifyView.code3.rx.text.orEmpty <-> code3).disposed(by: disposeBag)
        (smsVerifyView.code4.rx.text.orEmpty <-> code4).disposed(by: disposeBag)
        (smsVerifyView.code5.rx.text.orEmpty <-> code5).disposed(by: disposeBag)
        (smsVerifyView.code6.rx.text.orEmpty <-> code6).disposed(by: disposeBag)

        delegate.validateAccountType(validator: validator)
        let otpCode3 = Observable.combineLatest(code1, code2, code3).map { $0 + $1 + $2 }
        let otpCode6 = Observable.combineLatest(code4, code5, code6).map { $0 + $1 + $2 }
        let otpCode = Observable.combineLatest(otpCode3, otpCode6).map { $0 + $1 }
        otpCode.distinctUntilChanged().bind(onNext: {[weak self] text in self?.showPasscodeUncorrectTip(false) }).disposed(by: disposeBag)
        validator.isOtpValid.bind(to: btnVerify.rx.valid).disposed(by: disposeBag)
        otpCode.bind(to: validator.otp).disposed(by: disposeBag)
    }

    func setResendTimer() {
        resendTimer.start(timeInterval: 1, duration: Setting.resendOtpCountDownSecond) { [weak self] (index, countDownSecond, finish) in
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
        step2CountDownTimer.start(timeInterval: 1, duration: Setting.resetPasswordStep2CountDownSecond) { [weak self] (index, countDownSecond, finish) in
            if countDownSecond == 0 {
                self?.overStep2TimeLimit = true
            }
        }
    }

    private func handleError(_ error: Error) {
        if delegate.isProfileVerify && error.isUnauthorized() {
            SideBarViewController.showAuthorizationPage()
        } else {
            switch error {
            case is PlayerOtpCheckError:
                otpRetryCount += 1
                showPasscodeUncorrectTip(true)
                if otpRetryCount >= Setting.otpRetryLimit { navigateToErrorPage() }
            case is PlayerOverOtpRetryLimit:
                navigateToErrorPage()
            case is PlayerIpOverOtpDailyLimit:
                onExccedResendLimit()
            default:
                viewStatusTip.show(statusTip: Localize.string("common_unknownerror"), img: UIImage(named: "Failed"))
            }
        }
    }
    
    private func onExccedResendLimit() {
        Alert.show(Localize.string("common_tip_title_warm"), delegate.commonVerifyOtpArgs.otpExeedSendLimitError, confirm: {[weak self] in
            self?.showErrorPage()
        }, cancel: nil)
    }
    
    private func showErrorPage() {
        let commonFailViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
        commonFailViewController.commonFailedType = delegate.commonVerifyOtpArgs.commonFailedType
        NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
    }
    
    private func showPasscodeUncorrectTip(_ show: Bool) {
        constraintErrTipHeight.constant = show ? errTipHeight : 0
        constraintErrTipBottom.constant = show ? errTipBottom : 0
        viewErrTip.isHidden = !show
    }

    @IBAction func btnResendPressed(_ sender: UIButton) {
        if overStep2TimeLimit {
            navigateToErrorPage()
            return
        }

        delegate.resendOtp().subscribe {
            self.viewStatusTip.show(on: self.view, statusTip: Localize.string("common_otp_send_success"), img: UIImage(named: "Success"))
            self.setResendTimer()
        } onError: { (error) in
            self.viewStatusTip.show(on: self.view, statusTip: Localize.string("common_otp_send_fail"), img: UIImage(named: "Success"))
            self.setResendTimer()
            self.handleError(error)
        }.disposed(by: disposeBag)
    }

    @IBAction func btnVerifyPressed(_ sender: UIButton) {
        if overStep2TimeLimit {
            navigateToErrorPage()
            return
        }

        delegate.verify(otp: getOtpCode()).subscribe {[weak self] in
            self?.otpRetryCount = 0
        } onError: { (error) in
            self.handleError(error)
        }.disposed(by: disposeBag)
    }

    @IBAction func btnBackPressed(_ sender: UIButton) {
        delegate.onCloseVerifyProcess()
    }

    private func getOtpCode() -> String {
        var code = ""
        for c in [code1, code2, code3, code4, code5, code6] {
            code += c.value
        }

        return code
    }

    private func navigateToErrorPage() {
        let commonFailViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
        commonFailViewController.commonFailedType = delegate.commonVerifyOtpArgs.commonFailedType
        if NavigationManagement.sharedInstance.viewController != nil {
            NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
        } else {
            UIApplication.topViewController()?.navigationController?.pushViewController(commonFailViewController, animated: true)
        }
    }

    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension CommonVerifyOtpViewController: BarButtonItemable { }

extension CommonVerifyOtpViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}


protocol OtpViewControllerProtocol {
    func verify(otp: String) -> Completable
    func resendOtp() -> Completable
    func validateAccountType(validator: OtpValidator)
    func onCloseVerifyProcess()

    var isProfileVerify: Bool { get set }
    var commonVerifyOtpArgs: CommonVerifyOtpArgs { get }
}

extension OtpViewControllerProtocol {
   var isProfileVerify : Bool { get{ false } set{} }
}


protocol OtpValidatorDelegation {
    var otpAccountType: ReplaySubject<SharedBu.AccountType?> { get set }
    var otpPattern: Observable<OtpPattern> { get set }
    var otp: ReplaySubject<String> { get set }
    var isOtpValid: Observable<Bool> { get set }
}

class OtpValidator: OtpValidatorDelegation {
    var otpAccountType = ReplaySubject<SharedBu.AccountType?>.create(bufferSize: 1)
    var otpPattern: Observable<OtpPattern>
    var otp = ReplaySubject<String>.create(bufferSize: 1)
    var isOtpValid: Observable<Bool>

    let accountPatternGenerator: AccountPatternGenerator

    init(accountPatternGenerator: AccountPatternGenerator) {
        self.accountPatternGenerator = accountPatternGenerator
        self.otpPattern = otpAccountType.compactMap { $0 }.map { accountPatternGenerator.otp(type: $0) }
        self.isOtpValid = Observable.combineLatest(otpPattern, otp).map({ (pattern, input) in
            pattern.verify(digit: input)
        })
    }
}
