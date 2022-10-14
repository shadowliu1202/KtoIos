import UIKit
import RxSwift
import SharedBu

class CommonVerifyOtpViewController: CommonViewController {
    @IBOutlet weak var naviItem: UINavigationItem!
    @IBOutlet weak var labTitle: UILabel!
    @IBOutlet weak var labDesc: UILabel!
    @IBOutlet weak var labTip: UILabel!
    @IBOutlet weak var labJunkTip: UILabel!
    @IBOutlet private weak var labErrTip: UILabel!
    @IBOutlet private weak var viewErrTip: UIView!
    @IBOutlet private weak var viewStatusTip: ToastView!
    @IBOutlet private weak var smsVerifyView: SMSVerifyCodeInputView!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet weak var btnVerify: UIButton!
    @IBOutlet weak var btnResend: UIButton!
    @IBOutlet private weak var constraintLabelErrTipTop: NSLayoutConstraint!
    @IBOutlet private weak var constraintLabelErrTipBottom: NSLayoutConstraint!
    @IBOutlet private weak var constraintStatusTipBottom: NSLayoutConstraint!
    
    var delegate: OtpViewControllerProtocol!
    var barButtonItems: [UIBarButtonItem] = []

    private let errTipLabelPadding = CGFloat(12)
    private var disposeBag = DisposeBag()
    private let resendTimer = CountDownTimer()
    private let step2CountDownTimer = CountDownTimer()
    private var overStep2TimeLimit = false
    private var otpRetryCount = 0
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))
    lazy var validator: OtpValidatorDelegation = OtpValidator(accountPatternGenerator: accountPatternGenerator)
    private var accountPatternGenerator = DI.resolve(AccountPatternGenerator.self)!
    private let serviceStatusViewModel = DI.resolve(ServiceStatusViewModel.self)!

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.info("", tag: "KTO-876")
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
        delegate.validateAccountType(validator: validator)
        disposeBag.insert(
            validator.otpPattern.map { $0.validLength() }.bind(onNext: smsVerifyView.setOtpMaxLength),
            validator.isOtpValid.bind(to: btnVerify.rx.valid),
            smsVerifyView.getOtpCode().bind(to: validator.otp),
            smsVerifyView.getOtpCode().map { _ in false }.bind(onNext: showPasscodeUncorrectTip)
        )
    }

    func setResendTimer( _ duration: TimeInterval = Setting.resendOtpCountDownSecond) {
        resendTimer.start(timeInterval: 1, duration: duration) { [weak self] (index, countDownSecond, finish) in
            let isTimeUp = countDownSecond == 0
            let mm = isTimeUp ? 00 : countDownSecond / 60
            let ss = isTimeUp ? 00 : countDownSecond % 60
            let text = String(format: Localize.string("common_otp_resend_tips"), String(format: "%02d:%02d", mm, ss)) + " " + Localize.string("common_resendotp")
            let range = (text as NSString).range(of: Localize.string("common_resendotp"))
            let mutableAttributedString = NSMutableAttributedString(string: text, attributes: [
                .font: UIFont(name: "PingFangSC-Regular", size: 14.0)!,
                .foregroundColor: UIColor.textPrimaryDustyGray,
                .kern: 0.0
            ])

            mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.redForDark502, range: range)
            self?.btnResend.setAttributedTitle(mutableAttributedString, for: .normal)
            self?.btnResend.isEnabled = isTimeUp
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
                self.handleErrors(error)
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
        constraintLabelErrTipTop.constant = show ? errTipLabelPadding : 0
        constraintLabelErrTipBottom.constant = show ? errTipLabelPadding : 0
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
        Logger.shared.info("btnVerifyPressed", tag: "KTO-876")
        if overStep2TimeLimit {
            navigateToErrorPage()
            return
        }
        btnVerify.isValid = false
        smsVerifyView.getOtpCode().first()
            .flatMapCompletable(verifyOTP)
            .do(onDispose: enableBtnVerify)
            .subscribe(onError: handleError)
            .disposed(by: disposeBag)
    }
    
    private func verifyOTP(_ code: String?) -> Completable {
        delegate.verify(otp: code!)
    }
    
    private func enableBtnVerify() {
        btnVerify.isValid = true
    }

    @IBAction func btnBackPressed(_ sender: UIButton) {
        delegate.onCloseVerifyProcess()
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
    func validateAccountType(validator: OtpValidatorDelegation)
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
