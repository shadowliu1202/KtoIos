import Moya
import RxSwift
import sharedbu
import SwiftUI
import UIKit

class DepositViewController:
  LobbyViewController,
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
          self?.navigationController?.pushViewController(CryptoSelectorViewController(), animated: true)
        },
        cancel: nil)
  }
}

// MARK: - Navigation

extension DepositViewController {
  func pushToMethodPage(_ selection: DepositSelection) {
    switch selection.type {
    case .OfflinePayment:
      navigationController?
        .pushViewController(OfflinePaymentViewController(), animated: true)

    case .Crypto:
      presentCryptoDepositWarnings()

    case .CryptoMarket:
      navigationController?
        .pushViewController(
          StarMergerViewController(paymentGatewayID: selection.id),
          animated: true)

    default:
      guard let dto = (selection as? OnlinePayment)?.paymentDTO else { return }
      navigationController?
        .pushViewController(
          OnlinePaymentViewController(selectedOnlinePayment: dto),
          animated: true)
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
  func backToDeposit(segue _: UIStoryboardSegue) {
    NavigationManagement.sharedInstance.viewController = self
  }
}
