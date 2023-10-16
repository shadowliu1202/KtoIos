import Foundation
import RxSwift
import sharedbu
import SwiftUI
import UIKit

class OnlinePaymentViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var viewModel: OnlinePaymentViewModel
  @Injected private var alert: AlertProtocol

  private let selectedOnlinePayment: PaymentsDTO.Online?

  private let disposeBag = DisposeBag()

  init(
    selectedOnlinePayment: PaymentsDTO.Online?,
    viewModel: OnlinePaymentViewModel? = nil,
    alert: AlertProtocol? = nil)
  {
    self.selectedOnlinePayment = selectedOnlinePayment

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

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    Logger.shared.info("\(type(of: self)) viewDidLoad")

    super.viewDidLoad()
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
    self.navigationController?
      .pushViewController(JinYiDigitalViewController(), animated: true)
  }

  private func toOnlineWebPage(_ url: String) {
    Alert.shared.show(
      Localize.string("common_kindly_remind"),
      Localize.string("deposit_thirdparty_transaction_remind"),
      confirm: { [unowned self] in
        self.navigationController?
          .pushViewController(DepositThirdPartWebViewController(url: url), animated: true)
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
