import RxSwift
import sharedbu
import UIKit

class CommonVerifyOtpViewController: CommonViewController {
    @IBOutlet var naviItem: UINavigationItem!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var labTitle: UILabel!
    @IBOutlet var labDesc: UILabel!
    @IBOutlet var labTip: UILabel!
    @IBOutlet var labJunkTip: UILabel!
    @IBOutlet private var labErrTip: UILabel!
    @IBOutlet private var viewErrTip: UIView!
    @IBOutlet private var smsVerifyView: SMSVerifyCodeInputView!
    @IBOutlet private var btnBack: UIBarButtonItem!
    @IBOutlet var btnVerify: UIButton!
    @IBOutlet var btnResend: UIButton!
    @IBOutlet private var labTipButtonConstraint: NSLayoutConstraint!

    @Injected private var accountPatternGenerator: AccountPatternGenerator
    @Injected private var customerServiceViewModel: CustomerServiceViewModel
    @Injected private var serviceStatusViewModel: ServiceStatusViewModel
    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var alert: AlertProtocol

    private let resendTimer = CountDownTimer()

    private let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private let disposeBag = DisposeBag()

    private lazy var customService = UIBarButtonItem
        .kto(.cs(
            supportLocale: playerConfiguration.supportLocale,
            customerServiceViewModel: customerServiceViewModel,
            serviceStatusViewModel: serviceStatusViewModel,
            alert: alert,
            delegate: self,
            disposeBag: disposeBag))

    lazy var validator: OtpValidatorDelegation = OtpValidator(accountPatternGenerator: accountPatternGenerator)
    var delegate: OtpViewControllerProtocol!
    var barButtonItems: [UIBarButtonItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        bindingViews()
        setResendTimer()
        showToast(Localize.string("common_otp_send_success"), barImg: .success)
        showPasscodeUncorrectTip(false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationManagement.sharedInstance.viewController = self
    }

    private func initUI() {
        if !delegate.commonVerifyOtpArgs.isHiddenCSBarItem {
            bind(position: .right, barButtonItems: padding, customService)
        }

        if !delegate.commonVerifyOtpArgs.isHiddenBarTitle {
            let icon = if Configuration.current.isTestingEnvironment() { "NavigationIconDev" } else { "NavigationIcon" }
            naviItem.titleView = UIImageView(image: UIImage(named: icon))
        }

        scrollView.alwaysBounceVertical = true
        labTitle.text = delegate.commonVerifyOtpArgs.title
        labDesc.text = delegate.commonVerifyOtpArgs.description
        labTip.text = delegate.commonVerifyOtpArgs.identityTip
        labJunkTip.text = delegate.commonVerifyOtpArgs.junkTip
        btnVerify.layer.cornerRadius = 8
        btnVerify.layer.masksToBounds = true
        btnVerify.setBackgroundImage(UIImage(color: UIColor.primaryDefault), for: .disabled)
        btnVerify.setBackgroundImage(UIImage(color: UIColor.primaryDefault.withAlphaComponent(0.3)), for: .normal)
    }

    func bindingViews() {
        delegate.validateAccountType(validator: validator)
        disposeBag.insert(
            validator.otpPattern.map { $0.validLength() }.bind(onNext: smsVerifyView.setOtpMaxLength),
            validator.isOtpValid.bind(to: btnVerify.rx.valid),
            smsVerifyView.getOtpCode().bind(to: validator.otp),
            smsVerifyView.getOtpCode().map { _ in false }.bind(onNext: showPasscodeUncorrectTip))
    }

    func setResendTimer(_ duration: TimeInterval = Setting.resendOtpCountDownSecond) {
        resendTimer.start(timeInterval: 1, duration: duration) { [weak self] _, countDownSecond, _ in
            let isTimeUp = countDownSecond == 0
            let mm = isTimeUp ? 00 : countDownSecond / 60
            let ss = isTimeUp ? 00 : countDownSecond % 60
            let text = String(format: Localize.string("common_otp_resend_tips"), String(format: "%02d:%02d", mm, ss)) + " " +
                Localize.string("common_resendotp")
            let range = (text as NSString).range(of: Localize.string("common_resendotp"))
            let mutableAttributedString = NSMutableAttributedString(string: text, attributes: [
                .font: UIFont(name: "PingFangSC-Regular", size: 14.0)!,
                .foregroundColor: UIColor.textPrimary,
                .kern: 0.0,
            ])

            mutableAttributedString.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: UIColor.primaryDefault.withAlphaComponent(isTimeUp ? 1 : 0.5),
                range: range)
            self?.btnResend.setAttributedTitle(mutableAttributedString, for: .normal)
            self?.btnResend.titleLabel?.textAlignment = .center
            self?.btnResend.isEnabled = isTimeUp
        }
    }

    private func handleError(_ error: Error) {
        if delegate.isProfileVerify, error.isUnauthorized() {
            NavigationManagement.sharedInstance.navigateToAuthorization()
        }
        else {
            switch error {
            case is PlayerOtpCheckError:
                showPasscodeUncorrectTip(true)
            case is PlayerOverOtpRetryLimit:
                navigateToErrorPage()
            case is PlayerIpOverOtpDailyLimit:
                onExceedResendLimit()
            case is ApiException:
                navigateToErrorPage()
            default:
                super.handleErrors(error)
            }
        }
    }

    private func onExceedResendLimit() {
        Alert.shared.show(
            Localize.string("common_tip_title_warm"),
            delegate.commonVerifyOtpArgs.otpExeedSendLimitError,
            confirm: { [weak self] in
                self?.showErrorPage()
            },
            cancel: nil)
    }

    private func showErrorPage() {
        let commonFailViewController = UIStoryboard(name: "Common", bundle: nil)
            .instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
        commonFailViewController.commonFailedType = delegate.commonVerifyOtpArgs.commonFailedType
        NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
    }

    private func showPasscodeUncorrectTip(_ show: Bool) {
        labTipButtonConstraint.constant = show ? 40 : 30
        viewErrTip.isHidden = !show
    }

    @IBAction
    func btnResendPressed(_: UIButton) {
        delegate.resendOtp()
            .observe(on: MainScheduler.instance)
            .do(
                onSubscribe: { [btnResend] in
                    btnResend?.isValid = false
                },
                onDispose: { [btnResend] in
                    btnResend?.isValid = true
                })
            .subscribe(
                onCompleted: { [weak self] in
                    self?.showToast(Localize.string("common_otp_send_success"), barImg: .success)
                    self?.setResendTimer()
                },
                onError: { [weak self] in
                    self?.handleError($0)
                })
            .disposed(by: disposeBag)
    }

    @IBAction
    func btnVerifyPressed(_: UIButton) {
        Logger.shared.info("btnVerifyPressed", tag: "KTO-876")

        smsVerifyView.getOtpCode()
            .first()
            .flatMapCompletable { [delegate] in delegate!.verify(otp: $0!) }
            .do(
                onSubscribe: { [btnVerify] in btnVerify?.isValid = false },
                onDispose: { [btnVerify] in btnVerify?.isValid = true })
            .subscribe(
                onCompleted: { [unowned self] in onCompleted() },
                onError: { [unowned self] in handleError($0) })
            .disposed(by: disposeBag)
    }

    func onCompleted() {
        delegate.verifyOnCompleted { [unowned self] error in
            self.handleError(error)
        }
    }

    @IBAction
    func btnBackPressed(_: UIButton) {
        delegate.onCloseVerifyProcess()
    }

    private func navigateToErrorPage() {
        let commonFailViewController = UIStoryboard(name: "Common", bundle: nil)
            .instantiateViewController(withIdentifier: "CommonFailViewController") as! CommonFailViewController
        commonFailViewController.commonFailedType = delegate.commonVerifyOtpArgs.commonFailedType
        if NavigationManagement.sharedInstance.viewController != nil {
            NavigationManagement.sharedInstance.pushViewController(vc: commonFailViewController)
        }
        else {
            UIApplication.topViewController()?.navigationController?.pushViewController(commonFailViewController, animated: true)
        }
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
    func verifyOnCompleted(onError: @escaping (Error) -> Void)

    var isProfileVerify: Bool { get set }
    var commonVerifyOtpArgs: CommonVerifyOtpArgs { get }
}

extension OtpViewControllerProtocol {
    var isProfileVerify: Bool { get { false } set { } }
}

protocol OtpValidatorDelegation {
    var otpAccountType: ReplaySubject<sharedbu.AccountType?> { get set }
    var otpPattern: Observable<OtpPattern> { get set }
    var otp: ReplaySubject<String> { get set }
    var isOtpValid: Observable<Bool> { get set }
}

class OtpValidator: OtpValidatorDelegation {
    var otpAccountType = ReplaySubject<sharedbu.AccountType?>.create(bufferSize: 1)
    var otpPattern: Observable<OtpPattern>
    var otp = ReplaySubject<String>.create(bufferSize: 1)
    var isOtpValid: Observable<Bool>

    let accountPatternGenerator: AccountPatternGenerator

    init(accountPatternGenerator: AccountPatternGenerator) {
        self.accountPatternGenerator = accountPatternGenerator
        otpPattern = otpAccountType.compactMap { $0 }.map { accountPatternGenerator.otp(type: $0) }
        isOtpValid = Observable.combineLatest(otpPattern, otp).map { pattern, input in
            pattern.verify(digit: input)
        }
    }
}
