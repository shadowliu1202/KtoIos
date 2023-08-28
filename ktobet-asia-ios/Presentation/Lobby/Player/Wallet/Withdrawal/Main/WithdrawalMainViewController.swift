import Foundation
import RxSwift
import SharedBu
import UIKit

class WithdrawalMainViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var viewModel: WithdrawalMainViewModel
  @Injected private var alert: AlertProtocol

  private let disposeBag = DisposeBag()

  static func instance(
    viewModel: WithdrawalMainViewModel? = nil,
    alert: AlertProtocol? = nil)
    -> WithdrawalMainViewController
  {
    let vc = WithdrawalMainViewController.initFrom(storyboard: "Withdrawal")

    if let viewModel {
      vc._viewModel.wrappedValue = viewModel
    }

    if let alert {
      vc._alert.wrappedValue = alert
    }

    return vc
  }

  deinit {
    Injectable.resetObjectScope(.withdrawalFlow)
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    Logger.shared.info("\(type(of: self)) viewDidLoad")

    super.viewDidLoad()
    setupUI()
    binding()
  }
}

// MARK: - UI

extension WithdrawalMainViewController {
  func setupUI() {
    NavigationManagement.sharedInstance
      .addMenuToBarButtonItem(
        vc: self,
        title: Localize.string("common_withdrawal"))

    addSubView(
      from: { [weak self] in
        WithdrawalMainView(
          viewModel: viewModel,
          cryptoTurnOverOnClick: {
            self?.toCryptoLimitPage()
          },
          noneCryptoTurnOverOnClick: {
            self?.alertCryptoLimitInformation()
          },
          withdrawalOnAllowedFiat: {
            self?.toFiatBankcardPage()
          },
          withdrawalOnDisAllowedFiat: {
            self?.alertCryptoWithdrawalNeeded()
          },
          withdrawalOnAllowedCrypto: {
            self?.toCryptoBankcardPage()
          },
          withdrawalOnDisAllowedCrypto: {
            self?.alertFiatWithdrawalNeeded()
          },
          showAllRecordsOnTap: {
            self?.toWithdrawalLogs()
          },
          withdrawalRecordOnTap: { id, type in
            self?.toWithdrawalLogDetail(id, type)
          })
          .environment(\.playerLocale, viewModel.getSupportLocale())
      }, to: view)
  }

  func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }
}

// MARK: - Alert

extension WithdrawalMainViewController {
  func alertCryptoLimitInformation() {
    alert.show(
      Localize.string("cps_crpyto_withdrawal_requirement_title"),
      Localize.string("cps_crpyto_withdrawal_requirement_desc"),
      confirm: {
        self.dismiss(animated: true, completion: nil)
      },
      cancel: nil)
  }

  func alertFiatWithdrawalNeeded() {
    alert.show(
      nil,
      Localize.string("cps_withdrawal_all_fiat_first"),
      confirm: { },
      cancel: nil)
  }

  func alertCryptoWithdrawalNeeded() {
    if let (amount, simpleName) = viewModel.instruction?.cryptoWithdrawalRequirement {
      alert.show(
        Localize.string("cps_cash_withdrawal_lock_title"),
        Localize.string("cps_cash_withdrawal_lock_desc", amount + simpleName),
        confirm: {
          self.dismiss(animated: true, completion: nil)
        },
        cancel: nil)
    }
  }
}

// MARK: - Navigation

extension WithdrawalMainViewController {
  func toCryptoLimitPage() {
    navigationController?.pushViewController(WithdrawalCryptoLimitViewController(), animated: true)
  }

  func toFiatBankcardPage() {
    navigationController?
      .pushViewController(WithdrawalFiatWalletsViewController(), animated: true)
  }

  func toCryptoBankcardPage() {
    navigationController?
      .pushViewController(WithdrawalCryptoWalletsViewController(), animated: true)
  }

  func toWithdrawalLogs() {
    navigationController?
      .pushViewController(WithdrawalLogSummaryViewController(), animated: true)
  }

  func toWithdrawalLogDetail(_ id: String, _ type: WithdrawalDto.LogCurrencyType) {
    navigationController?
      .pushViewController(
        WithdrawalRecordDetailMainViewController(
          displayId: id,
          paymentCurrencyType: type),
        animated: true)
  }
}
