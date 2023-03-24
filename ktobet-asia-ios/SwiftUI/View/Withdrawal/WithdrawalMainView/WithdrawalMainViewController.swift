import Foundation
import RxSwift
import SharedBu
import UIKit

class WithdrawalMainViewController:
  UIViewController,
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
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    Logger.shared.info("\(type(of: self)) viewDidLoad")

    setupUI()
    binding()
  }

  @IBAction
  func backToWithdrawalMainPage(segue: UIStoryboardSegue) {
    NavigationManagement.sharedInstance.viewController = self
    if
      let vc = segue.source as? WithdrawalRequestConfirmViewController,
      vc.withdrawalSuccess
    {
      showToast(Localize.string("common_request_submitted"), barImg: .success)
    }
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
    if let (amount, simpleName) = viewModel.instruction?.turnoverRequirement {
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
    let vc = CrpytoTransationLogViewController.initFrom(storyboard: "Withdrawal")

    viewModel
      .getCryptoWithdrawalRequirement()
      .observe(on: MainScheduler.instance)
      .subscribe(
        onSuccess: { [weak self] accountCurrency in
          vc.crpytoWithdrawalRequirementAmount = accountCurrency

          self?.navigationController?.pushViewController(vc, animated: true)
        },
        onFailure: { [weak self] error in
          self?.handleErrors(error)
        })
      .disposed(by: disposeBag)
  }

  func toFiatBankcardPage() {
    let vc = WithdrawlLandingViewController.initFrom(storyboard: "Withdrawal")

    vc.bankCardType = .general

    navigationController?.pushViewController(vc, animated: true)
  }

  func toCryptoBankcardPage() {
    let vc = WithdrawlLandingViewController.initFrom(storyboard: "Withdrawal")

    vc.bankCardType = .crypto

    navigationController?.pushViewController(vc, animated: true)
  }

  func toWithdrawalLogs() {
    let vc = WithdrawalRecordViewController.initFrom(storyboard: "Withdrawal")

    navigationController?.pushViewController(vc, animated: true)
  }

  func toWithdrawalLogDetail(_ id: String, _ type: WithdrawalDto.LogCurrencyType) {
    let vc = WithdrawlRecordContainer.initFrom(storyboard: "Withdrawal")

    vc.displayId = id
    vc.transactionTransactionType = parseLogCurrencyType(type)

    navigationController?.pushViewController(vc, animated: true)
  }

  private func parseLogCurrencyType(_ type: WithdrawalDto.LogCurrencyType) -> TransactionType {
    switch type {
    case .fiat:
      return .withdrawal
    case .crypto:
      return .cryptowithdrawal
    default:
      fatalError("Should not reach here.")
    }
  }
}
