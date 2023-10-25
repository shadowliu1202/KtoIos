import RxSwift
import sharedbu
import UIKit

class CommonVerifyOtpViewController: CommonViewController {
  @IBOutlet weak var naviItem: UINavigationItem!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var labTitle: UILabel!
  @IBOutlet weak var labDesc: UILabel!
  @IBOutlet weak var labTip: UILabel!
  @IBOutlet weak var labJunkTip: UILabel!
  @IBOutlet private weak var labErrTip: UILabel!
  @IBOutlet private weak var viewErrTip: UIView!
  @IBOutlet private weak var smsVerifyView: SMSVerifyCodeInputView!
  @IBOutlet private weak var btnBack: UIBarButtonItem!
  @IBOutlet weak var btnVerify: UIButton!
  @IBOutlet weak var btnResend: UIButton!
  @IBOutlet private weak var labTipButtonConstraint: NSLayoutConstraint!

  private let accountPatternGenerator = Injectable.resolve(AccountPatternGenerator.self)!
  private let serviceStatusViewModel = Injectable.resolve(ServiceStatusViewModel.self)!

  private let resendTimer = CountDownTimer()
  private let step2CountDownTimer = CountDownTimer()
  
  private let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private let disposeBag = DisposeBag()
  
  private var overStep2TimeLimit = false
  private var otpRetryCount = 0
  private lazy var customService = UIBarButtonItem
    .kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))

  lazy var validator: OtpValidatorDelegation = OtpValidator(accountPatternGenerator: accountPatternGenerator)
  var delegate: OtpViewControllerProtocol!
  var barButtonItems: [UIBarButtonItem] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    Logger.shared.info("", tag: "KTO-876")
    
    initUI()
    bindingViews()
    setResendTimer()
    setStep2Timer()
    showToast(Localize.string("common_otp_send_success"), barImg: .success)
    showPasscodeUncorrectTip(false)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NavigationManagement.sharedInstance.viewController = self
  }

  private func initUI() {
    if !delegate.commonVerifyOtpArgs.isHiddenCSBarItem {
      self.bind(position: .right, barButtonItems: padding, customService)
    }
    
    if !delegate.commonVerifyOtpArgs.isHiddenBarTitle {
      naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
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
        .kern: 0.0
      ])

      mutableAttributedString.addAttribute(
        NSAttributedString.Key.foregroundColor,
        value: UIColor.primaryDefault.withAlphaComponent(isTimeUp ? 1 : 0.5),
        range: range)
      self?.btnResend.setAttributedTitle(mutableAttributedString, for: .normal)
      self?.btnResend.isEnabled = isTimeUp
    }
  }

  private func setStep2Timer() {
    step2CountDownTimer
      .start(timeInterval: 1, duration: Setting.resetPasswordStep2CountDownSecond) { [weak self] _, countDownSecond, _ in
        if countDownSecond == 0 {
          self?.overStep2TimeLimit = true
        }
      }
  }

  private func handleError(_ error: Error) {
    if delegate.isProfileVerify, error.isUnauthorized() {
      NavigationManagement.sharedInstance.navigateToAuthorization()
    }
    else {
      switch error {
      case is PlayerOtpCheckError:
        otpRetryCount += 1
        showPasscodeUncorrectTip(true)
        if otpRetryCount >= Setting.otpRetryLimit { navigateToErrorPage() }
      case is PlayerIpOverOtpDailyLimit:
        onExccedResendLimit()
      case is ApiException:
        navigateToErrorPage()
      default:
        super.handleErrors(error)
      }
    }
  }

  private func onExccedResendLimit() {
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
    if overStep2TimeLimit {
      navigateToErrorPage()
      return
    }

    delegate.resendOtp()
      .subscribe(
        onCompleted: { [weak self] in
          self?.showToast(Localize.string("common_otp_send_success"), barImg: .success)
          self?.setResendTimer()
        },
        onError: { [weak self] in
          self?.showToast(Localize.string("common_otp_send_fail"), barImg: .failed)
          self?.setResendTimer()
          self?.handleError($0)
        })
      .disposed(by: disposeBag)
  }

  @IBAction
  func btnVerifyPressed(_: UIButton) {
    Logger.shared.info("btnVerifyPressed", tag: "KTO-876")
    
    guard !overStep2TimeLimit else { navigateToErrorPage(); return }
    
    smsVerifyView.getOtpCode()
      .first()
      .flatMapCompletable { [delegate] in delegate!.verify(otp: $0!) }
      .do(
        onSubscribe: { [btnVerify] in btnVerify?.isValid = false },
        onDispose: { [btnVerify] in btnVerify?.isValid = true })
      .subscribe(
        onCompleted: { [delegate] in delegate?.verifyOnCompleted() },
        onError: { [unowned self] in handleError($0) })
      .disposed(by: disposeBag)
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

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
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
  func verifyOnCompleted()

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
    self.otpPattern = otpAccountType.compactMap { $0 }.map { accountPatternGenerator.otp(type: $0) }
    self.isOtpValid = Observable.combineLatest(otpPattern, otp).map({ pattern, input in
      pattern.verify(digit: input)
    })
  }
}
