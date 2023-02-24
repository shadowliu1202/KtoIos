import RxSwift
import SharedBu
import UIKit

class DepositOfflineConfirmViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol
  @Injected private var viewModel: DepositOfflineConfirmViewModel

  static let segueIdentifier = "toOfflineConfirmSegue"

  private let disposeBag = DisposeBag()

  /// Those parameter need to set before controller been presented
  var unwindSegueId = ""
  var memo: OfflineDepositDTO.Memo!
  var selectedBank: PaymentsDTO.BankCard!

  /// For unwind segue
  var confirmSuccess = false

  static func instantiate(
    memo: OfflineDepositDTO.Memo,
    selectedBank: PaymentsDTO.BankCard,
    unwindSegueId: String,
    viewModel: DepositOfflineConfirmViewModel? = nil)
    -> DepositOfflineConfirmViewController
  {
    let vc = DepositOfflineConfirmViewController.initFrom(storyboard: "Deposit")

    vc.memo = memo
    vc.selectedBank = selectedBank
    vc.unwindSegueId = unwindSegueId

    if let viewModel {
      vc._viewModel.wrappedValue = viewModel
    }

    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
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
    Logger.shared.info("\(type(of: self)) deinit")
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
            ToastView.show(
              statusTip: Localize.string("common_copied"),
              img: UIImage(named: "Success"),
              on: self.view)
          })
      },
      to: view)
  }

  private func binding() {
    viewModel.depositSuccessDriver
      .drive(onNext: { [unowned self] in
        self.confirmSuccess = true
        self.performSegue(withIdentifier: self.unwindSegueId, sender: nil)
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
