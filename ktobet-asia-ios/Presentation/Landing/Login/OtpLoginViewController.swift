import RxSwift
import sharedbu
import UIKit

class OtpLoginViewController: LandingViewController {
    static let segueIdentifier = "goOtpLoginSegue"

    static let accountRetryLimit = 11
    static let retryCountDownTime = 60

    @IBOutlet private var naviItem: UINavigationItem!
    @IBOutlet private var btnBack: UIBarButtonItem!
    @IBOutlet private var inputMobile: InputText!
    @IBOutlet private var inputEmail: InputText!
    @IBOutlet private var labResetTypeTip: UILabel!
    @IBOutlet private var labResetErrMessage: UILabel!
    @IBOutlet private var resetTypeSegmentView: UIView!
    @IBOutlet private var btnPhone: UIButton!
    @IBOutlet private var btnEmail: UIButton!
    @IBOutlet private var btnSubmit: UIButton!
    @IBOutlet private var viewRegistErrMessage: UIView!
    @IBOutlet private var viewInputView: UIView!
    @IBOutlet private var constraintResetErrorView: NSLayoutConstraint!
    @IBOutlet private var constraintResetErrorViewPadding: NSLayoutConstraint!

    @Injected private var viewModel: OtpLoginViewModel
    @Injected private var customerServiceViewModel: CustomerServiceViewModel
    @Injected private var serviceStatusViewModel: ServiceStatusViewModel
    @Injected private var alert: AlertProtocol
    private var otpStatus: OtpStatus? = nil

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == OtpLoginViewController.segueIdentifier {
            if let dest = segue.destination as? OtpLoginViewController {
                dest.otpStatus = sender as? OtpStatus
            }
        }
    }

    private var emptyStateView: EmptyStateView?
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem
        .kto(.cs(
            supportLocale: viewModel.getSupportLocale(),
            customerServiceViewModel: customerServiceViewModel,
            serviceStatusViewModel: serviceStatusViewModel,
            alert: alert,
            delegate: self,
            disposeBag: disposeBag
        ))

    private var inputAccount: InputText {
        switch selectedVerifyWay {
        case .email: return inputEmail
        case .phone: return inputMobile
        }
    }

    var barButtonItems: [UIBarButtonItem] = []

    private var isFirstTimeEnter = true
    private var selectedVerifyWay: AccountType = .phone
    private var remainTime = 0
    private let disposeBag = DisposeBag()
    private lazy var locale: SupportLocale = viewModel.getSupportLocale()
    override func viewDidLoad() {
        super.viewDidLoad()
        bind(position: .right, barButtonItems: padding, customService)
        initialize()
        setViewModel()
        viewModel.refreshOtpStatus()
    }

    private func initialize() {
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnPhone.setTitle(Localize.string("common_mobile"), for: .normal)
        btnEmail.setTitle(Localize.string("common_email"), for: .normal)
        inputEmail.setKeyboardType(.emailAddress)
        inputMobile.setKeyboardType(.numberPad)
        inputEmail.setTitle(Localize.string("common_email"))
        inputMobile.setTitle(Localize.string("common_mobile"))
        inputEmail.maxLength = Account.Email.companion.MAX_LENGTH
        btnSubmit.setTitle(Localize.string("common_next"), for: .normal)
        for button in [btnEmail, btnPhone] {
            let selectedColor = UIColor.greyScaleIconDisable
            let unSelectedColor = UIColor.clear
            button?.setBackgroundImage(UIImage(color: selectedColor), for: .selected)
            button?.setBackgroundImage(UIImage(color: unSelectedColor), for: .normal)
            button?.layer.cornerRadius = 8
            button?.layer.masksToBounds = true
        }

        inputMobile.setSubTitle("+\(locale.cellPhoneNumberFormat().areaCode())")
    }

    private func initEmptyStateView(hint: String) {
        emptyStateView?.removeFromSuperview()
        emptyStateView = EmptyStateView(
            icon: UIImage(named: "Maintenance"),
            description: hint,
            keyboardAppearance: .impossible
        )
        emptyStateView!.backgroundColor = .greyScaleDefault

        view.addSubview(emptyStateView!)

        emptyStateView!.snp.makeConstraints { make in
            make.top.equalTo(resetTypeSegmentView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setViewModel() {
        (inputMobile.text <-> viewModel.relayMobile).disposed(by: disposeBag)
        (inputEmail.text <-> viewModel.relayEmail).disposed(by: disposeBag)

        let event = viewModel.event()

        Observable.just(otpStatus ?? OtpStatus(isMailActive: true, isSmsActive: true))
            .concat(event.otpStatus)
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] otpStatus in
                guard let self else { return }
                self.constraintResetErrorView.constant = 0
                self.constraintResetErrorViewPadding.constant = 0
                guard !(!otpStatus.isSmsActive && self.isFirstTimeEnter)
                else {
                    self.btnEmailPressed(self.btnEmail!)
                    self.isFirstTimeEnter = false
                    return
                }
                switch self.selectedVerifyWay {
                case .phone:
                    self.displayMobileContent(isOTPActive: otpStatus.isSmsActive)
                case .email:
                    self.displayEmailContent(isOTPActive: otpStatus.isMailActive)
                }
            })
            .disposed(by: disposeBag)

        event.emailValid
            .subscribe(onNext: { [weak self] status in
                var message = ""
                if status == .errEmailFormat {
                    message = Localize.string("common_error_email_format")
                } else if status == .empty {
                    message = Localize.string("common_field_must_fill")
                }
                self?.labResetTypeTip.text = message
                self?.inputAccount.showUnderline(message.count > 0)
                self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)

        event.mobileValid
            .subscribe(onNext: { [weak self] status in
                var message = ""
                if status == .errPhoneFormat {
                    message = Localize.string("common_error_mobile_format")
                } else if status == .empty {
                    message = Localize.string("common_field_must_fill")
                }
                self?.labResetTypeTip.text = message
                self?.inputAccount.showUnderline(message.count > 0)
                self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)

        Observable.combineLatest(event.mobileValid, event.emailValid)
            .subscribe(onNext: { [weak self] mobileValid, emailValid in
                guard let self else { return }
                var isInputValid = false
                switch self.selectedVerifyWay {
                case .phone:
                    isInputValid = mobileValid == .valid
                        && self.remainTime == 0
                case .email:
                    isInputValid = emailValid == .valid
                        && self.remainTime == 0
                }
                self.btnSubmit.isValid = isInputValid
            })
            .disposed(by: disposeBag)
        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                print(error.localizedDescription)
                self?.handleError(error)
            })
            .disposed(by: disposeBag)
    }

    private func displayMobileContent(isOTPActive: Bool) {
        if isOTPActive {
            emptyStateView?.removeFromSuperview()
            viewInputView.isHidden = false
            inputEmail.isHidden = true
            inputMobile.isHidden = false
        } else {
            initEmptyStateView(hint: Localize.string("login_resetpassword_step1_sms_inactive"))
            viewInputView.isHidden = true
        }
    }

    private func displayEmailContent(isOTPActive: Bool) {
        if isOTPActive {
            emptyStateView?.removeFromSuperview()
            viewInputView.isHidden = false
            inputEmail.isHidden = false
            inputMobile.isHidden = true
        } else {
            initEmptyStateView(hint: Localize.string("login_resetpassword_step1_email_inactive"))
            viewInputView.isHidden = true
        }
    }

    private func handleError(_ error: Error) {
        switch error {
        case is PlayerIsInactive,
             is PlayerIsLocked,
             is PlayerIsNotExist,
             is PlayerForbidLoginByCurrency:
            break
        case is PlayerIsSuspend:
            labResetErrMessage.text = Localize.string("common_kick_out_suspend")
        case is PlayerIdOverOtpLimit,
             is PlayerIpOverOtpDailyLimit,
             is PlayerOverOtpRetryLimit:
            alertExceedResendLimit()
        case is PlayerOtpMailInactive,
             is PlayerOtpSmsInactive:
            viewModel.refreshOtpStatus()
        default:
            handleErrors(error)
        }
    }

    private func alertExceedResendLimit() {
        let message = selectedVerifyWay == .phone
            ? Localize.string("login_mobile_send_limit")
            : Localize.string("login_mail_send_limit")
        Alert.shared.show(
            Localize.string("common_tip_title_warm"),
            message,
            confirm: nil,
            cancel: nil,
            tintColor: UIColor.primaryDefault
        )
    }

    private func navigateToStep2() {
        let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil)
            .instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
        let viewController = OtpLoginStep2ViewController(
            identity: viewModel.getAccount(selectedVerifyWay),
            accountType: selectedVerifyWay
        )
        commonVerifyOtpViewController.delegate = viewController
        navigationController?.pushViewController(commonVerifyOtpViewController, animated: true)
    }
}

extension OtpLoginViewController {
    // MARK: BUTTON ACTION

    @IBAction
    func btnPhonePressed(_: Any) {
        btnPhone.isSelected = true
        btnEmail.isSelected = false
        hideKeyboard()
        selectedVerifyWay = .phone
        inputAccount.showKeyboard()
        viewModel.refreshOtpStatus()
    }

    @IBAction
    func btnEmailPressed(_: Any) {
        btnPhone.isSelected = false
        btnEmail.isSelected = true
        hideKeyboard()
        selectedVerifyWay = .email
        inputAccount.showKeyboard()
        viewModel.refreshOtpStatus()
    }
    
    func hideKeyboard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @IBAction
    func btnResetPasswordPressed(_: Any) {
        viewModel.requestOtpLogin(selectedVerifyWay)
            .observe(on: MainScheduler.instance)
            .do(
                onSubscribe: { [btnSubmit] in
                    btnSubmit?.isValid = false
                },
                onDispose: { [btnSubmit] in
                    btnSubmit?.isValid = true
                }
            )
            .subscribe(
                onCompleted: ({ [weak self] in
                    self?.navigateToStep2()
                }),
                onError: { [weak self] error in
                    self?.handleError(error)
                }
            )
            .disposed(by: disposeBag)
    }
}

extension OtpLoginViewController: BarButtonItemable {}

extension OtpLoginViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}
