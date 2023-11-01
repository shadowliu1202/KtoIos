import RxSwift
import sharedbu
import UIKit

class ResetPasswordStep3ViewController: LandingViewController {
  static let segueIdentifier = "toStep3Segue"
  @IBOutlet private weak var naviItem: UINavigationItem!
  @IBOutlet private weak var inputPassword: InputPassword!
  @IBOutlet private weak var inputCsPassword: InputConfirmPassword!
  @IBOutlet private weak var btnBack: UIBarButtonItem!
  @IBOutlet private weak var btnSubmit: UIButton!
  @IBOutlet private weak var labTitle: UILabel!
  @IBOutlet private weak var labDesc: UILabel!
  @IBOutlet private weak var labPasswordTip: UILabel!
  @IBOutlet private weak var labPasswordDesc: UILabel!
  
  @Injected private var viewModel: ResetPasswordViewModel
  @Injected private var customerServiceViewModel: CustomerServiceViewModel
  @Injected private var serviceStatusViewModel: ServiceStatusViewModel
  @Injected private var alert: AlertProtocol
  
  private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private lazy var customService = UIBarButtonItem
    .kto(.cs(
      supportLocale: viewModel.getSupportLocale(),
      customerServiceViewModel: customerServiceViewModel,
      serviceStatusViewModel: serviceStatusViewModel,
      alert: alert,
      delegate: self,
      disposeBag: disposeBag))

  private var disposeBag = DisposeBag()

  var barButtonItems: [UIBarButtonItem] = []
  var changePasswordSuccess = true

  override func viewDidLoad() {
    super.viewDidLoad()
    self.bind(position: .right, barButtonItems: padding, customService)
    initialize()
    setViewModel()
  }

  private func initialize() {
    naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
    inputPassword.setTitle(Localize.string("common_password"))
    inputCsPassword.setTitle(Localize.string("common_password_2"))
    labPasswordDesc.text = Localize.string("common_password_tips_1")
    labPasswordTip.text = ""
    inputPassword.setCorner(topCorner: true, bottomCorner: false)
    inputPassword.confirmPassword = inputCsPassword
    inputCsPassword.setCorner(topCorner: false, bottomCorner: true)
    btnSubmit.layer.cornerRadius = 8
    btnSubmit.layer.masksToBounds = true
  }

  private func setViewModel() {
    (self.inputPassword.text <-> self.viewModel.relayPassword).disposed(by: self.disposeBag)
    (self.inputCsPassword.text <-> self.viewModel.relayConfirmPassword).disposed(by: self.disposeBag)
    let event = viewModel.event()
    event.passwordValid
      .subscribe(onNext: { [weak self] status in
        self?.btnSubmit.isValid = false
        var message = ""
        if status == .valid {
          self?.btnSubmit.isValid = true
        }
        else if status == .errPasswordFormat {
          message = Localize.string("common_field_format_incorrect")
        }
        else if status == .errPasswordNotMatch {
          message = Localize.string("register_step2_password_not_match")
        }
        else if status == .empty {
          message = Localize.string("common_password_not_filled")
        }
        self?.labPasswordTip.text = message
        self?.inputCsPassword.showUnderline(message.count > 0)
        self?.inputCsPassword.setCorner(topCorner: false, bottomCorner: message.count == 0)
      }).disposed(by: disposeBag)
  }

  private func handleError(_ error: Error) {
    switch error {
    case is PlayerChangePasswordFail:
      performSegue(withIdentifier: CommonFailViewController.segueIdentifier, sender: nil)
    default:
      showToast(Localize.string("common_unknownerror"), barImg: .failed)
    }
  }

  @IBAction
  func btnBackPressed(_: Any) {
    let title = Localize.string("common_confirm_cancel_operation")
    let message = Localize.string("login_resetpassword_cancel_content")
    Alert.shared.show(title, message) {
      self.navigationController?.dismiss(animated: true, completion: nil)
    } cancel: { }
  }

  @IBAction
  func btnSubmitPressed(_: Any) {
    viewModel.doResetPassword().subscribe { [weak self] in
      self?.changePasswordSuccess = true
      self?.performSegue(withIdentifier: "unwindToLogin", sender: nil)
    } onError: { [weak self] error in
      self?.changePasswordSuccess = false
      self?.handleError(error)
    }.disposed(by: disposeBag)
  }

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if segue.identifier == CommonFailViewController.segueIdentifier {
      if let dest = segue.destination as? CommonFailViewController {
        dest.commonFailedType = ResetPasswrodFailedType(barItems: [padding, customService])
      }
    }
  }
}

extension ResetPasswordStep3ViewController: BarButtonItemable { }

extension ResetPasswordStep3ViewController: CustomServiceDelegate {
  func customServiceBarButtons() -> [UIBarButtonItem]? {
    [padding, customService]
  }
}
