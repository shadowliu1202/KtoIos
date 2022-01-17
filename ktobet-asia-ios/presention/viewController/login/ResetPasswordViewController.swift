import UIKit
import RxSwift
import SharedBu

class ResetPasswordViewController: LandingViewController {
    static let segueIdentifier = "goResetPasswordSegue"
    var barButtonItems: [UIBarButtonItem] = []
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var inputMobile : InputText!
    @IBOutlet private weak var inputEmail : InputText!
    @IBOutlet private weak var labResetTypeTip : UILabel!
    @IBOutlet private weak var labResetErrMessage : UILabel!
    @IBOutlet private weak var btnPhone: UIButton!
    @IBOutlet private weak var btnEmail: UIButton!
    @IBOutlet private weak var btnSubmit: UIButton!
    @IBOutlet private weak var viewRegistErrMessage : UIView!
    @IBOutlet private weak var viewOtpServiceDown : UIView!
    @IBOutlet private weak var viewInputView : UIView!
    @IBOutlet private weak var constraintResetErrorView: NSLayoutConstraint!
    @IBOutlet private weak var constraintResetErrorViewPadding: NSLayoutConstraint!
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(delegate: self, disposeBag: disposeBag))
    
    private var viewModel = DI.resolve(ResetPasswordViewModel.self)!
    private var disposeBag = DisposeBag()
    private var isFirstTimeEnter = true
    private var timerResend = CountDownTimer()
    private var locale : SupportLocale = SupportLocale.China()
    private var inputAccount : InputText {
        get{
            switch viewModel.currentAccountType() {
            case .email: return inputEmail
            case .phone: return inputMobile
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .right, barButtonItems: padding, customService)
        initialize()
        setViewModel()
        checkLimitAndLock()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initialize() {
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnPhone.setTitle(Localize.string("common_mobile"), for: .normal)
        btnEmail.setTitle(Localize.string("common_email"), for: .normal)
        inputEmail.setKeyboardType(.emailAddress)
        inputMobile.setKeyboardType(.numberPad)
        inputEmail.setTitle(Localize.string("common_email"))
        inputMobile.setTitle(Localize.string("common_mobile"))
        btnSubmit.setTitle(Localize.string("common_get_code"), for: .normal)
        for button in [btnEmail, btnPhone]{
            let selectedColor = UIColor.backgroundTabsGray
            let unSelectedColor = UIColor.clear
            button?.setBackgroundImage(UIImage(color: selectedColor), for: .selected)
            button?.setBackgroundImage(UIImage(color: unSelectedColor), for: .normal)
            button?.layer.cornerRadius = 8
            button?.layer.masksToBounds = true
        }
        
        inputMobile.setSubTitle("+\(locale.cellPhoneNumberFormat().areaCode())")
    }
    
    private func setViewModel() {
        viewModel.inputAccountType(.phone)
        viewModel.inputLocale(locale)
        
        (self.inputMobile.text <-> self.viewModel.relayMobile).disposed(by: self.disposeBag)
        (self.inputEmail.text <-> self.viewModel.relayEmail).disposed(by: self.disposeBag)
        
        let event = viewModel.event()
        event.otpValid.subscribe(onNext: { [weak self] status in
            guard let `self` = self else { return }
            if status == .errSMSOtpInactive || status == .errEmailOtpInactive {
                self.viewOtpServiceDown.isHidden = false
                self.viewInputView.isHidden = true
                if status == .errSMSOtpInactive && self.isFirstTimeEnter {
                    // 3.4.8.1 first time enter switch to email if sms inactive
                    self.btnEmailPressed(self.btnEmail!)
                    self.isFirstTimeEnter = false
                }
            } else {
                self.viewOtpServiceDown.isHidden = true
                self.viewInputView.isHidden = false
            }
        }).disposed(by: disposeBag)
        
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
        
        event.accountValid
            .bind(to: btnSubmit.rx.valid)
            .disposed(by: disposeBag)
        
        event.typeChange
            .subscribe(onNext: {[weak self] type in
                guard let `self` = self else { return }
                self.constraintResetErrorView.constant = 0
                self.constraintResetErrorViewPadding.constant = 0
                switch type {
                case .phone:
                    self.inputEmail.isHidden = true
                    self.inputMobile.isHidden = false
                    self.btnPhone.isSelected = true
                    self.btnEmail.isSelected = false
                    self.btnSubmit.setTitle(Localize.string("register_step2_verify_mobile"), for: .normal)
                case .email:
                    self.inputEmail.isHidden = false
                    self.inputMobile.isHidden = true
                    self.btnPhone.isSelected = false
                    self.btnEmail.isSelected = true
                    self.btnSubmit.setTitle(Localize.string("register_step2_verify_mail"), for: .normal)
                }
                self.inputAccount.showKeyboard()
            }).disposed(by: disposeBag)
    }
    
    private func handleError(_ error : Error) {
        let type = ErrorType(rawValue: (error as NSError).code)
        switch type {
        case .PlayerIsNotExist, .PlayerIsSuspend, .PlayerIsInactive, .PlayerIsLocked:
            constraintResetErrorView.constant = 56
            constraintResetErrorViewPadding.constant = 12
            if viewModel.retryCount >= ResetPasswordViewModel.accountRetryLimit {
                self.btnSubmit.isValid = false
                labResetErrMessage.text = Localize.string("common_error_try_later")
                setCountDownTimer()
            } else {
                labResetErrMessage.text = self.btnPhone.isSelected ? Localize.string("common_error_phone_verify") : Localize.string("common_error_email_verify")
            }
        case .PlayerIpOverOtpDailyLimit, .PlayerIdOverOtpLimit, .PlayerOverOtpRetryLimit:
            alertExceedResendLimit()
        default:
            self.handleErrors(error)
        }
    }
    
    private func checkLimitAndLock() {
        if viewModel.retryCount >= ResetPasswordViewModel.accountRetryLimit && self.viewModel.countDownEndTime != nil {
            setCountDownTimer()
        }
    }
    
    private func setCountDownTimer() {
        self.btnSubmit.isValid = false
        self.viewModel.countDownEndTime = self.viewModel.countDownEndTime == nil ? Date().adding(value: ResetPasswordViewModel.retryCountDownTime, byAdding: .second) : self.viewModel.countDownEndTime
        timerResend.start(timeInterval: 1, endTime: self.viewModel.countDownEndTime!) { [weak self] (index, countDownSecond, finish) in
            if countDownSecond != 0 {
                self?.btnSubmit.setTitle(Localize.string("common_get_code_countdown", "\(countDownSecond)"), for: .normal)
            } else {
                self?.btnSubmit.isValid = true
                self?.viewModel.countDownEndTime = nil
                self?.btnSubmit.setTitle(Localize.string("common_get_code"), for: .normal)
            }
            
            self?.viewModel.remainTime = countDownSecond
        }
    }
    
    private func alertExceedResendLimit() {
        let message = viewModel.currentAccountType() == .phone ? Localize.string("common_sms_otp_exeed_send_limit") : Localize.string("common_email_otp_exeed_send_limit")
        Alert.show(Localize.string("common_tip_title_warm"), message, confirm: nil, cancel: nil, tintColor: UIColor.red)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ResetPasswordStep2ViewController.segueIdentifier {
            if let dest = segue.destination as? ResetPasswordStep2ViewController {
                dest.viewModel = viewModel
            }
        }
    }
    
    override func abstracObserverUpdate() {
        self.observerCompulsoryUpdate()
    }
}

extension ResetPasswordViewController {
    // MARK: BUTTON ACTION
    @IBAction func btnPhonePressed(_ sender : Any){
        viewModel.inputAccountType(.phone)
    }
    
    @IBAction func btnEmailPressed(_ sender : Any){
        viewModel.inputAccountType(.email)
    }
    
    @IBAction func btnResetPasswordPressed(_ sender : Any) {
        viewModel.requestPasswordReset().subscribe { [weak self] in
            self?.viewModel.retryCount = 0
            self?.performSegue(withIdentifier: "toStep2Segue", sender: nil)
        } onError: { [weak self] (error) in
            self?.viewModel.retryCount += 1
            self?.handleError(error)
        }.disposed(by: disposeBag)
    }
}

extension ResetPasswordViewController: BarButtonItemable {}

extension ResetPasswordViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}
