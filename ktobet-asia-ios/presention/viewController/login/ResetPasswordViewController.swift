import RxSwift
import SharedBu
import UIKit

class ResetPasswordViewController: LandingViewController {
  static let segueIdentifier = "goResetPasswordSegue"
  var barButtonItems: [UIBarButtonItem] = []
  @IBOutlet private weak var naviItem: UINavigationItem!
  @IBOutlet private weak var btnBack: UIBarButtonItem!
  @IBOutlet private weak var inputMobile: InputText!
  @IBOutlet private weak var inputEmail: InputText!
  @IBOutlet private weak var labResetTypeTip: UILabel!
  @IBOutlet private weak var labResetErrMessage: UILabel!
  @IBOutlet private weak var btnPhone: UIButton!
  @IBOutlet private weak var btnEmail: UIButton!
  @IBOutlet private weak var btnSubmit: UIButton!
  @IBOutlet private weak var viewRegistErrMessage: UIView!
  @IBOutlet private weak var viewOtpServiceDown: UIView!
  @IBOutlet private weak var viewInputView: UIView!
  @IBOutlet private weak var constraintResetErrorView: NSLayoutConstraint!
  @IBOutlet private weak var constraintResetErrorViewPadding: NSLayoutConstraint!

  private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private let serviceStatusViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
  private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private lazy var customService = UIBarButtonItem
    .kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))

  private var viewModel = Injectable.resolve(ResetPasswordViewModel.self)!
  private var disposeBag = DisposeBag()
  private var isFirstTimeEnter = true
  private var timerResend = CountDownTimer()
  private lazy var locale: SupportLocale = localStorageRepo.getSupportLocale()
  private var inputAccount: InputText {
    switch viewModel.currentAccountType() {
    case .email: return inputEmail
    case .phone: return inputMobile
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
    inputEmail.maxLength = Account.Email.companion.MAX_LENGTH
    btnSubmit.setTitle(Localize.string("common_get_code"), for: .normal)
    for button in [btnEmail, btnPhone] {
      let selectedColor = UIColor.gray636366
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
      guard let self else { return }
      if status == .errSMSOtpInactive || status == .errEmailOtpInactive {
        self.viewOtpServiceDown.isHidden = false
        self.viewInputView.isHidden = true
        if status == .errSMSOtpInactive, self.isFirstTimeEnter {
          // 3.4.8.1 first time enter switch to email if sms inactive
          self.btnEmailPressed(self.btnEmail!)
        }
      }
      else {
        self.viewOtpServiceDown.isHidden = true
        self.viewInputView.isHidden = false
      }

      self.isFirstTimeEnter = false
    }).disposed(by: disposeBag)

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

    event.accountValid
      .bind(to: btnSubmit.rx.valid)
      .disposed(by: disposeBag)

    event.typeChange
      .subscribe(onNext: { [weak self] type in
        guard let self else { return }
        self.constraintResetErrorView.constant = 0
        self.constraintResetErrorViewPadding.constant = 0
        switch type {
        case .phone:
          self.inputEmail.isHidden = true
          self.inputMobile.isHidden = false
          self.btnPhone.isSelected = true
          self.btnEmail.isSelected = false
        case .email:
          self.inputEmail.isHidden = false
          self.inputMobile.isHidden = true
          self.btnPhone.isSelected = false
          self.btnEmail.isSelected = true
        }
        self.inputAccount.showKeyboard()
      }).disposed(by: disposeBag)
  }

  private func handleError(_ error: Error) {
    switch error {
    case is PlayerIsInactive,
         is PlayerIsLocked,
         is PlayerIsNotExist,
         is PlayerIsSuspend: constraintResetErrorView.constant = 56
      constraintResetErrorViewPadding.constant = 12
      if viewModel.retryCount >= ResetPasswordViewModel.accountRetryLimit {
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
    if viewModel.retryCount >= ResetPasswordViewModel.accountRetryLimit, self.viewModel.countDownEndTime != nil {
      setCountDownTimer()
    }
  }

  private func setCountDownTimer() {
    self.btnSubmit.isValid = false
    self.viewModel.countDownEndTime = self.viewModel.countDownEndTime == nil ? Date()
      .adding(value: ResetPasswordViewModel.retryCountDownTime, byAdding: .second) : self.viewModel.countDownEndTime
    timerResend.start(timeInterval: 1, endTime: self.viewModel.countDownEndTime!) { [weak self] _, countDownSecond, _ in
      if countDownSecond != 0 {
        self?.btnSubmit.setTitle(Localize.string("common_get_code_countdown", "\(countDownSecond)"), for: .normal)
      }
      else {
        self?.btnSubmit.isValid = true
        self?.viewModel.countDownEndTime = nil
        self?.btnSubmit.setTitle(Localize.string("common_get_code"), for: .normal)
      }

      self?.viewModel.remainTime = countDownSecond
    }
  }

  private func alertExceedResendLimit() {
    let message = viewModel.currentAccountType() == .phone ? Localize.string("common_sms_otp_exeed_send_limit") : Localize
      .string("common_email_otp_exeed_send_limit")
    Alert.shared.show(
      Localize.string("common_tip_title_warm"),
      message,
      confirm: nil,
      cancel: nil,
      tintColor: UIColor.redF20000)
  }

  private func navigateToStep2() {
    let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil)
      .instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
    let resetPasswordStep2ViewController = ResetPasswordStep2ViewController(
      identity: viewModel.getAccount(),
      accountType: viewModel.currentAccountType())
    commonVerifyOtpViewController.delegate = resetPasswordStep2ViewController
    self.navigationController?.pushViewController(commonVerifyOtpViewController, animated: true)
  }
}

extension ResetPasswordViewController {
  // MARK: BUTTON ACTION
  @IBAction
  func btnPhonePressed(_: Any) {
    viewModel.inputAccountType(.phone)
  }

  @IBAction
  func btnEmailPressed(_: Any) {
    viewModel.inputAccountType(.email)
  }

  @IBAction
  func btnResetPasswordPressed(_: Any) {
    viewModel.requestPasswordReset().subscribe { [weak self] in
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
