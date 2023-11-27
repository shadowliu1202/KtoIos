import RxSwift
import sharedbu
import UIKit

class DepositOfflineConfirmViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol
  @Injected private var viewModel: DepositOfflineConfirmViewModel

  private let disposeBag = DisposeBag()

  private var unwindType: UIViewController.Type?

  let memo: OfflineDepositDTO.Memo
  let selectedBank: PaymentsDTO.BankCard

  init(
    viewModel: DepositOfflineConfirmViewModel? = nil,
    memo: OfflineDepositDTO.Memo,
    selectedBank: PaymentsDTO.BankCard,
    alert: AlertProtocol? = nil)
  {
    self.memo = memo
    self.selectedBank = selectedBank

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

  override func willMove(toParent parent: UIViewController?) {
    guard
      let navigation = parent as? UINavigationController,
      let root = navigation.viewControllers.first
    else { return }

    unwindType = type(of: root)
  }

  override func handleErrors(_ error: Error) {
    if error is PlayerDepositCountOverLimit {
      self.notifyTryLaterAndPopBack()
    }
    else {
      super.handleErrors(error)
    }
  }

  deinit {
    Injectable.resetObjectScope(.depositFlow)
  }
}

// MARK: - UI

extension DepositOfflineConfirmViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .close,
      action: #selector(close))

    addSubView(
      from: { [unowned self] in
        DepositOfflineConfirmView(
          viewModel: self.viewModel,
          memo: self.memo,
          selectedBank: self.selectedBank,
          onCopyed: {
            self.showToast(Localize.string("common_copied"), barImg: .success)
          })
      },
      to: view)
  }

  private func binding() {
    viewModel.depositSuccessDriver
      .drive(onNext: { [unowned self] in
        if self.unwindType == DepositViewController.self {
          self.showToast(Localize.string("deposit_offline_step3_title"), barImg: .success)
          NavigationManagement.sharedInstance.popToRootViewController()
        }
        else if
          self.unwindType == NotificationViewController.self,
          let detail = self.navigationController?.viewControllers.first(where: { $0 is NotificationDetailViewController })
        {
          self.showToast(Localize.string("common_request_submitted"), barImg: .success)
          NavigationManagement.sharedInstance.popViewController(nil, to: detail)
        }
      })
      .disposed(by: disposeBag)

    viewModel.expiredDriver
      .drive(onNext: {
        NavigationManagement.sharedInstance.popToRootViewController()
      })
      .disposed(by: disposeBag)

    viewModel.errors()
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }

  @objc
  private func close() {
    alert.show(
      Localize.string("common_confirm_cancel_operation"),
      Localize.string("deposit_offline_termniate"),
      confirm: {
        NavigationManagement.sharedInstance.popToRootViewController()
      },
      confirmText: Localize.string("common_determine"),
      cancel: { },
      cancelText: Localize.string("common_cancel"))
  }

  private func notifyTryLaterAndPopBack() {
    alert.show(
      nil,
      Localize.string("deposit_notify_request_later"),
      confirm: {
        NavigationManagement.sharedInstance.popViewController()
      })
  }
}
