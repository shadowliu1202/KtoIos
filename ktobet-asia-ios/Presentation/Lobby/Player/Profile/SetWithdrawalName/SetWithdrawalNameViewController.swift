import RxCocoa
import RxSwift
import sharedbu
import UIKit

class SetWithdrawalNameViewController: LobbyViewController, AuthProfileVerification {
  static let segueIdentifier = "toSetWithdrawalName"

  @IBOutlet weak var realNameInput: InputText!
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var submitBtn: UIButton!

  private var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    dataBinding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func dataBinding() {
    (self.realNameInput.text <-> self.viewModel.relayRealName).disposed(by: self.disposeBag)
    viewModel.verifyAccountNameError.bind(onNext: { [unowned self] accountNameException in
      let message = self.viewModel.transformExceptionToMessage(accountNameException)
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
      }).catch({ [weak self] in
        self?.handleErrors($0)
        self?.submitBtn.isEnabled = true
        return Observable.error($0)
      }).retry()
      .subscribe(onNext: { [weak self] in
        self?.popThenToastSuccess()
      }).disposed(by: disposeBag)
  }

  override func handleErrors(_ error: Error) {
    if error is KtoRealNameEditForbidden {
      self.errorLabel.text = Localize.string("profile_real_name_edit_forbidden")
    }
    else if error.isUnauthorized() {
      self.navigateToAuthorization()
    }
    else {
      super.handleErrors(error)
    }
  }

  private func popThenToastSuccess() {
    NavigationManagement.sharedInstance.popViewController({ [weak self] in
      self?.showToast(Localize.string("common_setting_done"), barImg: .success)
    })
  }
}
