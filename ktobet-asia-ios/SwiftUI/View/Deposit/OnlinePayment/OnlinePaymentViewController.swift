import Foundation
import RxSwift
import SharedBu
import SwiftUI
import UIKit

class OnlinePaymentViewController:
  LobbyViewController,
  SwiftUIConverter
{
  static let segueIdentifier = "toOnlinePaymentSegue"

  var selectedOnlinePayment: PaymentsDTO.Online!

  private let viewModel: OnlinePaymentViewModel
  private let alert: AlertProtocol

  private let disposeBag = DisposeBag()

  init?(
    coder: NSCoder,
    selectedOnlinePayment: PaymentsDTO.Online?,
    viewModel: OnlinePaymentViewModel,
    alert: AlertProtocol)
  {
    self.selectedOnlinePayment = selectedOnlinePayment
    self.viewModel = viewModel
    self.alert = alert

    super.init(coder: coder)
  }

  required init?(coder: NSCoder) {
    self.viewModel = Injectable.resolveWrapper(OnlinePaymentViewModel.self)
    self.alert = Injectable.resolveWrapper(AlertProtocol.self)

    super.init(coder: coder)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    Logger.shared.info("\(type(of: self)) viewDidLoad")

    setupUI()
    binding()
  }

  @objc
  func back() {
    Alert.shared.show(
      Localize.string("common_confirm_cancel_operation"),
      viewModel.getTerminateAlertMessage(),
      confirm: {
        NavigationManagement.sharedInstance.popViewController()
      },
      cancel: { })
  }

  override func handleErrors(_ error: Error) {
    if error is PlayerDepositCountOverLimit {
      self.notifyTryLaterAndPopBack()
    }
    else {
      super.handleErrors(error)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == DepositThirdPartWebViewController.segueIdentifier {
      if let dest = segue.destination as? DepositThirdPartWebViewController {
        dest.url = sender as? String
      }
    }
  }
}

// MARK: - UI

extension OnlinePaymentViewController {
  func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: .back,
        action: #selector(back))

    addSubView(
      from: {
        OnlinePaymentView(
          viewModel: viewModel,
          onlinePaymentDTO: selectedOnlinePayment,
          userGuideOnTap: { [weak self] in
            self?.toJinYiUserGuidePage()
          },
          remitButtonOnSuccess: { [weak self] url in
            self?.toOnlineWebPage(url)
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

// MARK: - Navigation

extension OnlinePaymentViewController {
  private func toJinYiUserGuidePage() {
    NavigationManagement.sharedInstance.viewController
      .performSegue(
        withIdentifier: JinYiDigitalViewController.segueIdentifier,
        sender: nil)
  }

  private func toOnlineWebPage(_ url: String) {
    Alert.shared.show(
      Localize.string("common_kindly_remind"),
      Localize.string("deposit_thirdparty_transaction_remind"),
      confirm: {
        NavigationManagement.sharedInstance.viewController
          .performSegue(
            withIdentifier: DepositThirdPartWebViewController.segueIdentifier,
            sender: url)
      },
      cancel: nil)
  }

  private func notifyTryLaterAndPopBack() {
    alert.show(
      nil,
      Localize.string("deposit_notify_request_later"),
      confirm: {
        NavigationManagement.sharedInstance.popViewController()
      },
      cancel: nil)
  }
}
