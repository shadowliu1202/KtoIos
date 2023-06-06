import RxSwift
import SharedBu
import UIKit

class WithdrawalFiatRequestStep1ViewController:
  LobbyViewController,
  AuthProfileVerification,
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol
  @Injected private var viewModel: WithdrawalFiatRequestStep1ViewModel

  private let wallet: WithdrawalDto.FiatWallet
  private let disposeBag = DisposeBag()

  init(
    viewModel: WithdrawalFiatRequestStep1ViewModel? = nil,
    alert: AlertProtocol? = nil,
    wallet: WithdrawalDto.FiatWallet)
  {
    self.wallet = wallet

    if let viewModel {
      self._viewModel.wrappedValue = viewModel
    }

    if let alert {
      self._alert.wrappedValue = alert
    }

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension WithdrawalFiatRequestStep1ViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: .back,
        action: #selector(tapBack))

    addSubView(
      from: { [unowned self] in
        WithdrawalFiatRequestStep1View(
          viewModel: self.viewModel,
          wallet: self.wallet,
          onRealNameClick: { editable in
            editable ? self.goToEditRealName() : self.showUsernameCannotEditAlert()
          },
          toStep2: {
            self.navigationController?
              .pushViewController(
                WithdrawalFiatRequestStep2ViewController(
                  wallet: self.wallet,
                  amount: self.viewModel.amount,
                  isRealNameEditable: self.viewModel.realNameInfo?.editable ?? false),
                animated: true)
          })
      },
      to: view)
  }

  private func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }

  private func goToEditRealName() {
    alert.show(
      Localize.string("withdrawal_bankcard_change_confirm_title"),
      Localize.string("withdrawal_bankcard_change_confirm_content"),
      confirm: { [weak self] in
        self?.navigateToAuthorization()
      },
      confirmText: Localize.string("common_moveto"),
      cancel: { })
  }

  private func showUsernameCannotEditAlert() {
    alert.show(
      Localize.string("withdrawal_realname_modal_title"),
      Localize.string("withdrawal_realname_modal_content"),
      confirm: nil,
      cancel: nil)
  }

  @objc
  private func tapBack() {
    view.endEditing(true)
    alert.show(
      Localize.string("withdrawal_cancel_title"),
      Localize.string("withdrawal_cancel_content"),
      confirm: {
        NavigationManagement.sharedInstance.back()
      },
      confirmText: Localize.string("common_yes"),
      cancel: { },
      cancelText: Localize.string("common_no"))
  }
}
