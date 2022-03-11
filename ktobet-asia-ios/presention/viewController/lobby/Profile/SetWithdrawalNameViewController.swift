import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SetWithdrawalNameViewController: APPViewController {
    static let segueIdentifier = "toSetWithdrawalName"
    
    @IBOutlet weak var realNameInput: InputText!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var submitBtn: UIButton!
    
    private var viewModel = DI.resolve(ModifyProfileViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func dataBinding() {
        (self.realNameInput.text <-> self.viewModel.relayRealName).disposed(by: self.disposeBag)
        viewModel.verifyAccountNameError.bind(onNext: { [unowned self] accountNameException in
            var message = ""
            switch accountNameException {
            case is AccountNameException.EmptyAccountName:
                message = Localize.string("common_field_must_fill")
            case is AccountNameException.InvalidNameFormat:
                message = Localize.string("register_step2_name_format_error")
            case is AccountNameException.ExceededLength:
                message = Localize.string("register_name_format_error_length_limitation", "\(self.viewModel.accountNameMaxLength)")
            default:
                break
            }
            self.errorLabel.text = message
            self.realNameInput.showUnderline(message.count > 0)
            self.realNameInput.setCorner(topCorner: true, bottomCorner: message.count == 0)
        }).disposed(by: disposeBag)
        viewModel.isAccountNameValid.bind(to: submitBtn.rx.isValid).disposed(by: disposeBag)
        submitBtn.rx.touchUpInside
            .do(onNext: { [weak self] in
                self?.submitBtn.isEnabled = false
            }).flatMap({ [unowned self] _ -> Observable<Void> in
                let name = self.viewModel.relayRealName.value
                return self.viewModel.modifyWithdrawalName(name: name).andThen(.just(()))
            }).catchError({ [weak self] in
                self?.handleErrors($0)
                self?.submitBtn.isEnabled = true
                return Observable.error($0)
            }).retry()
            .subscribe(onNext: { [weak self] in
                self?.popThenToastSuccess()
            }).disposed(by: disposeBag)
    }
    
    private func navigateToAuthorization() {
        navigationController?.dismiss(animated: true, completion: nil)
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let navi = storyboard.instantiateViewController(withIdentifier: "AuthProfileModificationNavigation")
        navi.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        NavigationManagement.sharedInstance.viewController.present(navi, animated: true, completion: nil)
    }
    
    override func handleErrors(_ error: Error, ktoExceptionsHandle: ((_ exception: ApiException) -> ())? = nil) {
        if error is KtoRealNameEditForbidden {
            self.errorLabel.text = Localize.string("profile_real_name_edit_forbidden")
        } else if error.isUnauthorized() {
            self.navigateToAuthorization()
        } else {
            super.handleErrors(error)
        }
    }
    
    private func popThenToastSuccess() {
        NavigationManagement.sharedInstance.popViewController({ [weak self] in
            self?.showToastOnBottom(Localize.string("common_setting_done"), img: UIImage(named: "Success"))
        })
    }
    
}
