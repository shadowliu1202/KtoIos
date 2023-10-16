import RxCocoa
import RxSwift
import sharedbu
import Swinject
import UIKit

class SignupUserinfoViewController: LandingViewController {
  @IBOutlet private weak var naviItem: UINavigationItem!

  @IBOutlet private weak var btnBack: UIBarButtonItem!
  @IBOutlet private weak var btnSubmit: UIButton!
  @IBOutlet private weak var btnPhone: UIButton!
  @IBOutlet private weak var btnEmail: UIButton!

  @IBOutlet private weak var labTitle: UILabel!
  @IBOutlet private weak var labDesc: UILabel!
  @IBOutlet private weak var labRegistErrMessage: UILabel!
  @IBOutlet private weak var labAccountTip: UILabel!
  @IBOutlet private weak var labNameTip: UILabel!
  @IBOutlet private weak var labPasswordTip: UILabel!
  @IBOutlet private weak var labPasswordDesc: UILabel!

  @IBOutlet private weak var inputMobile: InputText!
  @IBOutlet private weak var inputEmail: InputText!
  @IBOutlet private weak var inputName: InputText!
  @IBOutlet private weak var inputPassword: InputPassword!
  @IBOutlet private weak var inputCsPassword: InputConfirmPassword!

  @IBOutlet private weak var scrollView: UIScrollView!
  @IBOutlet private weak var viewButtons: UIView!
  @IBOutlet private weak var viewRegistErrMessage: UIView!

  @IBOutlet private weak var constraintRegistErrMessageHeight: NSLayoutConstraint!
  
  private var emptyStateView: EmptyStateView?
  
  var barButtonItems: [UIBarButtonItem] = []
  lazy var locale: SupportLocale = localStorageRepo.getSupportLocale()
  private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private lazy var customService = UIBarButtonItem
    .kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))

  private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private let errMsgHeight = CGFloat(56)
  private let segueLanguage = "BackToLanguageList"
  private let seguePhone = "GoToPhone"
  private let segueEmail = "GoToEmail"
  private var isFirstTimeEnter = true
  private var accountPatternGenerator = Injectable.resolve(AccountPatternGenerator.self)!
  private var viewModel = Injectable.resolve(SignupUserInfoViewModel.self)!
  private let serviceStatusViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
  private var inputAccount: InputText {
    switch viewModel.currentAccountType() {
    case .email: return inputEmail
    case .phone: return inputMobile
    }
  }

  private var countryCode: String {
    "+\(accountPatternGenerator.mobileNumber().areaCode())"
  }

  private var disposeBag = DisposeBag()

  // MARK: LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bind(position: .right, barButtonItems: padding, customService)
    localize()
    defaultStyle()
    setViewModel()
  }
  
  override func handleErrors(_ error: Error) {
    switch error {
    case is PlayerIpOverOtpDailyLimit: displayError(error: Localize.string("common_email_otp_exeed_send_limit"))
    case is DBPlayerAlreadyExist:
      switch viewModel.currentAccountType() {
      case .email: displayError(error: Localize.string("common_error_email_verify"))
      case .phone: displayError(error: Localize.string("common_error_phone_verify"))
      }
    case is PlayerOtpMailInactive,
         is PlayerOtpSmsInactive:
      viewModel.refreshOtpStatus()
    case is KtoPlayerRegisterBlock: alertRegistrationBlock()
    default: displayError(error: String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)"))
    }
  }

  // MARK: METHOD
  func localize() {
    btnPhone.setTitle(Localize.string("common_mobile"), for: .normal)
    btnEmail.setTitle(Localize.string("common_email"), for: .normal)
    btnSubmit.setTitle(Localize.string("register_step2_verify_mobile"), for: .normal)
    inputEmail.setTitle(Localize.string("common_email"))
    inputMobile.setTitle(Localize.string("common_mobile"))
    inputName.setTitle(Localize.string("common_realname"))
    inputPassword.setTitle(Localize.string("common_password"))
    inputCsPassword.setTitle(Localize.string("common_password_2"))
    labTitle.text = Localize.string("register_step2_title_1")
    labDesc.text = Localize.string("register_step2_title_2")
    labPasswordDesc.text = Localize.string("common_password_tips_1")
  }

  func defaultStyle() {
    naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
    constraintRegistErrMessageHeight.constant = 0
    viewRegistErrMessage.isHidden = true
    viewRegistErrMessage.layer.cornerRadius = 8
    viewRegistErrMessage.layer.masksToBounds = true
    viewButtons.layer.cornerRadius = 8
    viewButtons.layer.masksToBounds = true
    labAccountTip.text = ""
    labNameTip.text = ""
    labPasswordTip.text = ""
    inputMobile.setCorner(topCorner: true, bottomCorner: true)
    inputMobile.setKeyboardType(.phonePad)
    inputMobile.setSubTitle(countryCode)
    inputEmail.setCorner(topCorner: true, bottomCorner: true)
    inputEmail.setKeyboardType(.emailAddress)
    inputEmail.maxLength = Account.Email.companion.MAX_LENGTH
    inputName.setCorner(topCorner: true, bottomCorner: true)
    inputPassword.setCorner(topCorner: true, bottomCorner: false)
    inputPassword.confirmPassword = inputCsPassword
    inputCsPassword.inputPassword = inputPassword
    inputCsPassword.setCorner(topCorner: false, bottomCorner: true)
    btnSubmit.layer.cornerRadius = 8
    btnSubmit.layer.masksToBounds = true
    btnSubmit.backgroundColor = UIColor.primaryDefault
    btnSubmit.isValid = false

    for button in [btnEmail, btnPhone] {
      let selectedColor = UIColor.greyScaleIconDisable
      let unSelectedColor = UIColor.clear
      button?.setBackgroundImage(UIImage(color: selectedColor), for: .selected)
      button?.setBackgroundImage(UIImage(color: unSelectedColor), for: .normal)
      button?.layer.cornerRadius = 8
      button?.layer.masksToBounds = true
    }
  }

  func setViewModel() {
    viewModel.inputAccountType(.phone)
    viewModel.inputLocale(locale)

    (self.inputMobile.text <-> self.viewModel.relayMobile).disposed(by: self.disposeBag)
    (self.inputEmail.text <-> self.viewModel.relayEmail).disposed(by: self.disposeBag)
    (self.inputName.text <-> self.viewModel.relayName).disposed(by: self.disposeBag)
    (self.inputPassword.text <-> self.viewModel.relayPassword).disposed(by: self.disposeBag)
    (self.inputCsPassword.text <-> self.viewModel.relayConfirmPassword).disposed(by: self.disposeBag)

    let event = viewModel.event()
    event.otpValid
      .subscribe(onNext: { [weak self] status in
        guard let self else { return }
        if !status.isMailActive, !status.isSmsActive {
          let title = Localize.string("common_error")
          let message = Localize.string("register_service_down")
          Alert.shared.show(title, message, confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
          }, cancel: nil)
        }

        if !status.isSmsActive, self.isFirstTimeEnter {
          self.btnEmailPressed(self.btnEmail!)
        }
        self.isFirstTimeEnter = false
        switch self.viewModel.currentAccountType() {
        case .email:
          self.selectedAccountTypeIsMaintain(isActive: status.isMailActive, otpStatus: status)
        case .phone:
          self.selectedAccountTypeIsMaintain(isActive: status.isSmsActive, otpStatus: status)
        }
      }).disposed(by: disposeBag)

    event.emailValid
      .subscribe(onNext: { [weak self] status in
        guard status != .doNothing else { return }
        var message = ""
        if status == .errEmailFormat {
          message = Localize.string("common_error_email_format")
        }
        else if status == .empty {
          message = Localize.string("common_field_must_fill")
        }
        self?.labAccountTip.text = message
        self?.inputAccount.showUnderline(message.count > 0)
        self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
      }).disposed(by: disposeBag)

    event.mobileValid
      .subscribe(onNext: { [weak self] status in
        guard status != .doNothing else { return }
        var message = ""
        if status == .errPhoneFormat {
          message = Localize.string("common_error_mobile_format")
        }
        else if status == .empty {
          message = Localize.string("common_field_must_fill")
        }
        self?.labAccountTip.text = message
        self?.inputAccount.showUnderline(message.count > 0)
        self?.inputAccount.setCorner(topCorner: true, bottomCorner: message.count == 0)
      }).disposed(by: disposeBag)

    event.nameValid
      .subscribe(onNext: { [unowned self] status in
        let message = AccountPatternGeneratorFactory.transform(self.viewModel.accountPatternGenerator, status)
        self.labNameTip.text = message
        self.inputName.showUnderline(message.count > 0)
        self.inputName.setCorner(topCorner: true, bottomCorner: message.count == 0)
      }).disposed(by: disposeBag)

    event.passwordValid
      .subscribe(onNext: { [weak self] status in
        var message = ""
        if status == .errPasswordFormat {
          message = Localize.string("common_field_format_incorrect")
        }
        else if status == .errPasswordNotMatch {
          message = Localize.string("register_step2_password_not_match")
        }
        else if status == .empty {
          message = Localize.string("common_field_must_fill")
        }
        self?.labPasswordTip.text = message
        self?.inputCsPassword.showUnderline(message.count > 0)
        self?.inputCsPassword.setCorner(topCorner: false, bottomCorner: message.count == 0)
      }).disposed(by: disposeBag)

    event.dataValid
      .bind(to: btnSubmit.rx.valid)
      .disposed(by: disposeBag)

    event.typeChange
      .subscribe(onNext: { [weak self] type in
        switch type {
        case .phone:
          self?.inputEmail.isHidden = true
          self?.inputMobile.isHidden = false
          self?.btnPhone.isSelected = true
          self?.btnEmail.isSelected = false
          self?.btnSubmit.setTitle(Localize.string("register_step2_verify_mobile"), for: .normal)
        case .email:
          self?.inputEmail.isHidden = false
          self?.inputMobile.isHidden = true
          self?.btnPhone.isSelected = false
          self?.btnEmail.isSelected = true
          self?.btnSubmit.setTitle(Localize.string("register_step2_verify_mail"), for: .normal)
        }
        self?.view.endEditing(true)
        self?.inputAccount.setContent("")
        self?.inputAccount.textContent.sendActions(for: .editingChanged)
        self?.hideError()
      }).disposed(by: disposeBag)
  }
  
  private func selectedAccountTypeIsMaintain(isActive: Bool, otpStatus: OtpStatus) {
    if !isActive {
      showServiceInactiveView(status: otpStatus)
    }
    else {
      emptyStateView?.removeFromSuperview()
    }
  }
  
  private func showServiceInactiveView(status: OtpStatus) {
    self.view.layoutIfNeeded()
    
    let emptyStateHint = {
      if !status.isSmsActive {
        return Localize.string("register_step2_sms_inactive")
      }

      if !status.isMailActive {
        return Localize.string("register_step2_sms_inactive")
      }

      return ""
    }()
    
    showEmptyStateView(hint: emptyStateHint)
  }
  
  private func showEmptyStateView(hint: String) {
    emptyStateView?.removeFromSuperview()
    emptyStateView = EmptyStateView(
      icon: UIImage(named: "Maintenance"),
      description: hint,
      keyboardAppearance: .impossible)
    emptyStateView!.backgroundColor = .greyScaleDefault
    
    view.addSubview(emptyStateView!)

    emptyStateView!.snp.makeConstraints { make in
      make.top.equalTo(viewButtons.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }
  }
  
  private func alertRegistrationBlock() {
    Alert.shared.show(
      Localize.string("common_tip_title_warm"),
      Localize.string("register_step2_unusual_activity"),
      confirm: { [unowned self] in navigationController?.dismiss(animated: true) },
      confirmText: Localize.string("common_determine"))
  }

  func displayError(error: String) {
    self.viewRegistErrMessage.isHidden = false
    self.labRegistErrMessage.text = error
    self.constraintRegistErrMessageHeight.constant = errMsgHeight
  }

  func hideError() {
    self.viewRegistErrMessage.isHidden = true
    self.labRegistErrMessage.text = ""
    self.constraintRegistErrMessageHeight.constant = 0
  }
}

extension SignupUserinfoViewController {
  // MARK: PAGE ACTION
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if
      let vcMail = segue.destination as? SignupEmailViewController,
      let userInfo = sender as? [String: String],
      let account = userInfo["account"],
      let password = userInfo["password"]
    {
      vcMail.account = account
      vcMail.password = password
    }
  }

  override func unwind(for _: UIStoryboardSegue, towards _: UIViewController) { }
  @IBAction
  func backToUserInfo(segue _: UIStoryboardSegue) { }
}

extension SignupUserinfoViewController {
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
  func btnBackPressed(_: Any) {
    let title = Localize.string("common_tip_title_unfinished")
    let message = Localize.string("common_tip_content_unfinished")
    Alert.shared.show(title, message) {
      self.performSegue(withIdentifier: self.segueLanguage, sender: nil)
    } cancel: { }
  }

  @IBAction
  func btnSubmitPressed(_: Any) {
    viewModel.register()
      .subscribe(
        onSuccess: { [weak self] info in
          guard let self else { return }
          let para = [
            "account": info.account,
            "password": info.password
          ]
          switch info.type {
          case .email: self.performSegue(withIdentifier: self.segueEmail, sender: para)
          case .phone: self.navigateToPhoneVerifyPage(para["account"] ?? "")
          }
        },
        onFailure: { [unowned self] in handleErrors($0) })
      .disposed(by: disposeBag)
  }

  func navigateToPhoneVerifyPage(_ account: String) {
    let commonVerifyOtpViewController = UIStoryboard(name: "Common", bundle: nil)
      .instantiateViewController(withIdentifier: "CommonVerifyOtpViewController") as! CommonVerifyOtpViewController
    let signupPhoneViewController = SignupPhoneViewController(phoneNumber: account, countryCode: countryCode)
    commonVerifyOtpViewController.delegate = signupPhoneViewController
    self.navigationController?.pushViewController(commonVerifyOtpViewController, animated: true)
  }
}

extension SignupUserinfoViewController: BarButtonItemable { }

extension SignupUserinfoViewController: CustomServiceDelegate {
  func customServiceBarButtons() -> [UIBarButtonItem]? {
    [padding, customService]
  }
}
