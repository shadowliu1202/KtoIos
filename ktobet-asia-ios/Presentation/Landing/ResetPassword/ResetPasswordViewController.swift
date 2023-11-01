import RxSwift
import sharedbu
import UIKit

class ResetPasswordViewController: LandingViewController {
  static let segueIdentifier = "goResetPasswordSegue"
  
  static let accountRetryLimit = 11
  static let retryCountDownTime = 60
  
  @IBOutlet private weak var naviItem: UINavigationItem!
  @IBOutlet private weak var btnBack: UIBarButtonItem!
  @IBOutlet private weak var inputMobile: InputText!
  @IBOutlet private weak var inputEmail: InputText!
  @IBOutlet private weak var labResetTypeTip: UILabel!
  @IBOutlet private weak var labResetErrMessage: UILabel!
  @IBOutlet private weak var resetTypeSegmentView: UIView!
  @IBOutlet private weak var btnPhone: UIButton!
  @IBOutlet private weak var btnEmail: UIButton!
  @IBOutlet private weak var btnSubmit: UIButton!
  @IBOutlet private weak var viewRegistErrMessage: UIView!
  @IBOutlet private weak var viewInputView: UIView!
  @IBOutlet private weak var constraintResetErrorView: NSLayoutConstraint!
  @IBOutlet private weak var constraintResetErrorViewPadding: NSLayoutConstraint!

  @Injected private var viewModel: ResetPasswordViewModel
  @Injected private var customerServiceViewModel: CustomerServiceViewModel
  @Injected private var serviceStatusViewModel: ServiceStatusViewModel
  @Injected private var alert: AlertProtocol
  
  private var emptyStateView: EmptyStateView?
  private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private lazy var customService = UIBarButtonItem
    .kto(.cs(
      supportLocale: viewModel.getSupportLocale(),
      customerServiceViewModel: customerServiceViewModel,
      serviceStatusViewModel: serviceStatusViewModel,
      alert: alert,
      delegate: self,
      disposeBag: disposeBag))
  
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

  private let timerResend = CountDownTimer()
  private lazy var locale: SupportLocale = viewModel.getSupportLocale()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.bind(position: .right, barButtonItems: padding, customService)
    initialize()
    setViewModel()
    checkLimitAndLock()
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
    btnSubmit.setTitle(Localize.string("common_get_code"), for: .normal)
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
      keyboardAppearance: .impossible)
    emptyStateView!.backgroundColor = .greyScaleDefault

    view.addSubview(emptyStateView!)

    emptyStateView!.snp.makeConstraints { make in
      make.top.equalTo(resetTypeSegmentView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }
  }

  private func setViewModel() {
    viewModel.inputLocale(locale)

    (self.inputMobile.text <-> self.viewModel.relayMobile).disposed(by: self.disposeBag)
    (self.inputEmail.text <-> self.viewModel.relayEmail).disposed(by: self.disposeBag)

    let event = viewModel.event()
    
    event.otpStatus
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
        }
        else if status == .empty {
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
        }
        else if status == .empty {
          message = Localize.string("common_field_must_fill")
        }
        self?.labResetTypeTip.text = message
        self?.inputAccount.showUnderline(message.count > 0)
        self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
      }).disposed(by: disposeBag)
    
    Observable.combineLatest(
      event.mobileValid,
      event.emailValid)
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
      
      inputAccount.showKeyboard()
    }
    else {
      initEmptyStateView(hint: Localize.string("login_resetpassword_step1_sms_inactive"))
      viewInputView.isHidden = true
      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }
  
  private func displayEmailContent(isOTPActive: Bool) {
    if isOTPActive {
      emptyStateView?.removeFromSuperview()
      viewInputView.isHidden = false
      
      inputEmail.isHidden = false
      inputMobile.isHidden = true
      
      inputAccount.showKeyboard()
    }
    else {
      initEmptyStateView(hint: Localize.string("login_resetpassword_step1_email_inactive"))
      viewInputView.isHidden = true
      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }

  private func handleError(_ error: Error) {
    switch error {
    case is PlayerIsInactive,
         is PlayerIsLocked,
         is PlayerIsNotExist,
         is PlayerIsSuspend:
      constraintResetErrorView.constant = 56
      constraintResetErrorViewPadding.constant = 12
      
      if viewModel.retryCount >= Self.accountRetryLimit {
        self.btnSubmit.isValid = false
        labResetErrMessage.text = Localize.string("common_error_try_later")
        setCountDownTimer()
      }
      else {
        labResetErrMessage.text = self.btnPhone.isSelected ? Localize.string("common_error_phone_verify") : Localize
          .string("common_error_email_verify")
      }
    case is PlayerIdOverOtpLimit,
         is PlayerIpOverOtpDailyLimit,
         is PlayerOverOtpRetryLimit:
      alertExceedResendLimit()
    case is PlayerOtpMailInactive,
         is PlayerOtpSmsInactive:
      viewModel.refreshOtpStatus()
    default:
      self.handleErrors(error)
    }
  }

  private func checkLimitAndLock() {
    if viewModel.retryCount >= Self.accountRetryLimit, self.viewModel.countDownEndTime != nil {
      setCountDownTimer()
    }
  }

  private func setCountDownTimer() {
    self.btnSubmit.isValid = false
    self.viewModel.countDownEndTime = self.viewModel.countDownEndTime == nil ? Date()
      .adding(value: Self.retryCountDownTime, byAdding: .second) : self.viewModel.countDownEndTime
    timerResend.start(timeInterval: 1, endTime: self.viewModel.countDownEndTime!) { [weak self] _, countDownSecond, _ in
      if countDownSecond != 0 {
        self?.btnSubmit.setTitle(Localize.string("common_get_code_countdown", "\(countDownSecond)"), for: .normal)
      }
      else {
        self?.btnSubmit.isValid = true
        self?.viewModel.countDownEndTime = nil
        self?.btnSubmit.setTitle(Localize.string("common_get_code"), for: .normal)
      }

      self?.remainTime = countDownSecond
    }
  }

  private func alertExceedResendLimit() {
    let message = selectedVerifyWay == .phone
      ? Localize.string("common_sms_otp_exeed_send_limit")
      : Localize.string("common_email_otp_exeed_send_limit")
    
    Alert.shared.show(
      Localize.string("common_tip_title_warm"),
      message,
      confirm: nil,
      cancel: nil,
      tintColor: UIColor.primaryDefault)
  }

  private func navigateToStep2() {
    let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil)
      .instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
    let resetPasswordStep2ViewController = ResetPasswordStep2ViewController(
      identity: viewModel.getAccount(selectedVerifyWay),
      accountType: selectedVerifyWay)
    commonVerifyOtpViewController.delegate = resetPasswordStep2ViewController
    self.navigationController?.pushViewController(commonVerifyOtpViewController, animated: true)
  }
}

extension ResetPasswordViewController {
  // MARK: BUTTON ACTION
  @IBAction
  func btnPhonePressed(_: Any) {
    btnPhone.isSelected = true
    btnEmail.isSelected = false
    
    selectedVerifyWay = .phone
    viewModel.refreshOtpStatus()
  }

  @IBAction
  func btnEmailPressed(_: Any) {
    btnPhone.isSelected = false
    btnEmail.isSelected = true
    
    selectedVerifyWay = .email
    viewModel.refreshOtpStatus()
  }

  @IBAction
  func btnResetPasswordPressed(_: Any) {
    viewModel.requestPasswordReset(selectedVerifyWay).subscribe { [weak self] in
      self?.viewModel.retryCount = 0
      self?.navigateToStep2()
    } onError: { [weak self] error in
      self?.viewModel.retryCount += 1
      self?.handleError(error)
    }.disposed(by: disposeBag)
  }
}

extension ResetPasswordViewController: BarButtonItemable { }

extension ResetPasswordViewController: CustomServiceDelegate {
  func customServiceBarButtons() -> [UIBarButtonItem]? {
    [padding, customService]
  }
}
