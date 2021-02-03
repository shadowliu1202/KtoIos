import UIKit
import RxSwift


class ResetPasswordStep3ViewController: UIViewController {
    static let segueIdentifier = "toStep3Segue"
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var inputPassword : InputPassword!
    @IBOutlet private weak var inputCsPassword : InputConfirmPassword!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnSubmit: UIButton!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var labPasswordTip : UILabel!
    @IBOutlet private weak var labPasswordDesc : UILabel!
    @IBOutlet private weak var viewStatusTip : ToastView!
    
    private var viewModel = DI.resolve(ResetPasswordViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var changePasswordSuccess = true

    override func viewDidLoad() {
        super.viewDidLoad()
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
            .subscribe(onNext: { status in
                self.btnSubmit.isValid = false
                var message = ""
                if status == .valid {
                    self.btnSubmit.isValid = true
                } else if status == .errPasswordFormat {
                    message = Localize.string("common_field_format_incorrect")
                } else if status == .errPasswordNotMatch{
                    message = Localize.string("register_step2_password_not_match")
                } else if status == .empty {
                    message = Localize.string("common_password_not_filled")
                }
                self.labPasswordTip.text = message
                self.inputCsPassword.showUnderline(message.count > 0)
                self.inputCsPassword.setCorner(topCorner: false, bottomCorner: message.count == 0)
            }).disposed(by: disposeBag)
    }
    
    private func handleError(_ error: Error) {
        let type = ErrorType(rawValue: (error as NSError).code)
        switch type {
        case .PlayerChangePasswordFail:
            performSegue(withIdentifier: SignupRegistFailViewController.segueIdentifier, sender: nil)
        default:
            viewStatusTip.show(statusTip: Localize.string("common_unknownerror"), img: UIImage(named: "Failed"))
        }
    }

    @IBAction func btnBackPressed(_ sender : Any){
        let title = Localize.string("common_confirm_cancel_operation")
        let message = Localize.string("login_resetpassword_cancel_content")
        Alert.show(title, message) {
            self.navigationController?.dismiss(animated: true, completion: nil)
        } cancel: {}
    }
    
    @IBAction func btnSubmitPressed(_ sender : Any){
        viewModel.doResetPassword().subscribe {
            self.changePasswordSuccess = true
            self.performSegue(withIdentifier: "unwindToLogin", sender: nil)
        } onError: { (error) in
            self.changePasswordSuccess = false
            self.handleError(error)
        }.disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SignupRegistFailViewController.segueIdentifier {
            if let dest = segue.destination as? SignupRegistFailViewController {
                dest.failedType = .resetPassword
            }
        }
    }
}
