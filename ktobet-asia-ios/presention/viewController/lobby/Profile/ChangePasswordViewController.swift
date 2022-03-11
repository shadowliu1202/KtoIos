import UIKit
import RxSwift
import RxCocoa
import SharedBu

class ChangePasswordViewController: APPViewController {
    static let segueIdentifier = "goChangePassword"
    @IBOutlet weak var errorViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var inputPassword: InputPassword!
    @IBOutlet private weak var inputConfirm: InputConfirmPassword!
    @IBOutlet private weak var labPasswordError: UILabel!
    @IBOutlet private weak var labPasswordTip: UILabel!
    @IBOutlet weak var btnSubmit: UIButton!
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        inputPassword.setTitle(Localize.string("common_password"))
        inputConfirm.setTitle(Localize.string("common_password_2"))
        inputPassword.setCorner(topCorner: true, bottomCorner: false)
        inputPassword.confirmPassword = inputConfirm
        inputConfirm.inputPassword = inputPassword
        inputConfirm.setCorner(topCorner: false, bottomCorner: true)
    }
    
    private func dataBinding() {
        (self.inputPassword.text <-> self.viewModel.relayChangePassword).disposed(by: self.disposeBag)
        (self.inputConfirm.text <-> self.viewModel.relayConfirmPassword).disposed(by: self.disposeBag)
        viewModel.passwordValidationError.subscribe(onNext: { [weak self] status in
            var message = ""
            if status == .errPasswordFormat {
                message = Localize.string("common_field_format_incorrect")
            } else if status == .errPasswordNotMatch {
                message = Localize.string("register_step2_password_not_match")
            } else if status == .empty {
                message = Localize.string("common_password_not_filled")
            }
            self?.labPasswordError.text = message
            self?.inputConfirm.showUnderline(message.count > 0)
            self?.inputConfirm.setCorner(topCorner: false, bottomCorner: message.count == 0)
        }).disposed(by: disposeBag)
        viewModel.isPasswordValid.bind(to: btnSubmit.rx.isValid).disposed(by: disposeBag)
        btnSubmit.rx.touchUpInside
            .do(onNext: { [weak self] in
                self?.btnSubmit.isEnabled = false
            }).flatMap({ [unowned self] _ -> Observable<Void> in
                let password = self.viewModel.relayChangePassword.value
                return self.viewModel.changePassword(password: password).andThen(.just(()))
            }).catchError({ [weak self] in
                self?.handleError($0)
                self?.btnSubmit.isEnabled = true
                return Observable.error($0)
            }).retry()
            .subscribe(onNext: { [weak self] in
                self?.errorViewHeight.constant = 0
                self?.popThenToast()
            }).disposed(by: disposeBag)

        Observable.combineLatest(inputPassword.text, inputConfirm.text).map { $0 + $1 }
            .distinctUntilChanged().bind(onNext: { [weak self] _ in self?.errorViewHeight.constant = 0 })
            .disposed(by: disposeBag)
    }
    
    private func handleError(_ error: Error) {
        if error is KtoPasswordRepeat {
            errorViewHeight.constant = 53
        } else if error.isUnauthorized() {
            navigateToAuthorization()
        } else {
            handleErrors(error)
        }
    }
    
    private func navigateToAuthorization() {
        navigationController?.dismiss(animated: true, completion: nil)
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let navi = storyboard.instantiateViewController(withIdentifier: "AuthProfileModificationNavigation")
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        NavigationManagement.sharedInstance.viewController.present(navi, animated: true, completion: nil)
    }
    
    private func popThenToast() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToastOnBottom(Localize.string("common_setting_done"), img: UIImage(named: "Success"))
        })
    }
}
