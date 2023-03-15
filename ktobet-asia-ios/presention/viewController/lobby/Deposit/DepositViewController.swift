import Moya
import RxSwift
import SharedBu
import SwiftUI
import UIKit

class DepositViewController: LobbyViewController,
  SwiftUIConverter
{
  @Injected private var playerConfig: PlayerConfiguration
  @Injected private var viewModel: DepositViewModel

  private let disposeBag = DisposeBag()

  init?(coder: NSCoder, viewModel: DepositViewModel, playerConfig: PlayerConfiguration) {
    super.init(coder: coder)
    self.viewModel = viewModel
    self.playerConfig = playerConfig
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  deinit {
    Injectable.resetObjectScope(.depositFlow)
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier {
    case StarMergerViewController.segueIdentifier:
      if let dest = segue.destination as? StarMergerViewController {
        dest.paymentGatewayID = (sender as? String)!
      }
    case OnlinePaymentViewController.segueIdentifier:
      if let dest = segue.destination as? OnlinePaymentViewController {
        dest.selectedOnlinePayment = (sender as? OnlinePayment)!.paymentDTO
      }
    default:
      break
    }
  }
}

// MARK: - UI

extension DepositViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(
      vc: self,
      title: Localize.string("common_deposit"))

    addSubView(
      from: { [unowned self] in
        DepositView(
          playerConfig: self.playerConfig,
          viewModel: self.viewModel,
          onMethodSelected: {
            self.pushToMethodPage($0)
          },
          onHistorySelected: {
            self.pushToRecordPage($0)
          },
          onDisplayAll: {
            self.pushToAllRecordPage()
          })
      },
      to: view)
  }

  private func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)
  }

  private func presentCryptoDepositWarnings() {
    Alert.shared
      .show(
        Localize.string("common_tip_title_warm"),
        Localize.string("deposit_crypto_warning"),
        confirm: { [weak self] in
          self?.navigationController?.pushViewController(CryptoSelectorViewController.instantiate(), animated: true)
        },
        cancel: nil)
  }
}

// MARK: - Navigation

extension DepositViewController {
  func pushToMethodPage(_ selection: DepositSelection) {
    switch selection.type {
    case .OfflinePayment:
      navigationController?.pushViewController(OfflinePaymentViewController(), animated: true)
    case .Crypto:
      self.presentCryptoDepositWarnings()
    case .CryptoMarket:
      self.performSegue(withIdentifier: StarMergerViewController.segueIdentifier, sender: selection.id)
    default:
      self.performSegue(withIdentifier: OnlinePaymentViewController.segueIdentifier, sender: selection)
    }
  }

  func pushToRecordPage(_ log: PaymentLogDTO.Log) {
    let detailMainViewController = DepositRecordDetailMainViewController(
      displayId: log.displayId,
      paymentCurrencyType: log.currencyType)

    navigationController?.pushViewController(detailMainViewController, animated: true)
  }

  func pushToAllRecordPage() {
    navigationController?.pushViewController(DepositLogSummaryViewController(), animated: true)
  }

  @IBAction
  func backToDeposit(segue: UIStoryboardSegue) {
    NavigationManagement.sharedInstance.viewController = self

    switch segue.source {
    case is DepositOfflineConfirmViewController:
      let confirm = segue.source as! DepositOfflineConfirmViewController

      if confirm.confirmSuccess {
        showToast(Localize.string("deposit_offline_step3_title"), barImg: .success)
      }

    case is DepositThirdPartWebViewController:
      showToast(Localize.string("common_request_submitted"), barImg: .success)

    default:
      break
    }
  }
}
