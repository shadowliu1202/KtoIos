import RxSwift
import SharedBu
import UIKit

class WithdrawalFiatRequestStep2ViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol
  @Injected private var viewModel: WithdrawalFiatRequestStep2ViewModel

  private let wallet: WithdrawalDto.FiatWallet
  private let amount: String

  private let disposeBag = DisposeBag()

  init(
    viewModel: WithdrawalFiatRequestStep2ViewModel? = nil,
    alert: AlertProtocol? = nil,
    wallet: WithdrawalDto.FiatWallet,
    amount: String,
    isRealNameEditable: Bool)
  {
    self.wallet = wallet
    self.amount = amount

    if let viewModel {
      self._viewModel.wrappedValue = viewModel
    }

    if let alert {
      self._alert.wrappedValue = alert
    }

    super.init(nibName: nil, bundle: nil)

    self.viewModel.isRealNameEditable = isRealNameEditable
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  override func handleErrors(_ error: Error) {
    if error is KtoPlayerWithdrawalDefective {
      alert.show(
        "",
        Localize.string("withdrawal_fail"),
        confirm: {
          NavigationManagement.sharedInstance.popToRootViewController()
        },
        cancel: nil)
    }
    else {
      super.handleErrors(error)
    }
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension WithdrawalFiatRequestStep2ViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: .back,
        action: #selector(tapBack))

    addSubView(
      from: { [unowned self] in
        WithdrawalFiatRequestStep2View(
          viewModel: self.viewModel,
          wallet: self.wallet,
          amount: self.amount,
          onSubmit: {
            self.handleSubmit()
          },
          onSuccess: {
            NavigationManagement.sharedInstance.popToRootViewController({
              @Injected var snackBar: SnackBar
              snackBar.show(tip: Localize.string("common_request_submitted"), image: UIImage(named: "Success"))
            })
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

  @objc
  private func tapBack() {
    view.endEditing(true)
    alert.show(
      Localize.string("withdrawal_cancel_title"),
      Localize.string("withdrawal_cancel_content"),
      confirm: {
        NavigationManagement.sharedInstance.popToRootViewController()
      },
      confirmText: Localize.string("common_yes"),
      cancel: { },
      cancelText: Localize.string("common_no"))
  }

  private func handleSubmit() {
    if viewModel.isRealNameEditable {
      alert.show(
        Localize.string("withdrawal_success_confirm_title", wallet.name),
        Localize.string("withdrawal_success_confirm_content"),
        confirm: { [weak self] in
          self?.viewModel.submitWithdrawal()
        },
        cancel: nil)
    }
    else {
      viewModel.submitWithdrawal()
    }
  }
}
