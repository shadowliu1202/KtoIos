import Combine
import RxSwift
import sharedbu
import SwiftUI
import UIKit

class WithdrawalAddFiatBankCardViewController:
  LobbyViewController,
  AuthProfileVerification,
  SwiftUIConverter
{
  @Injected var viewModel: WithdrawalAddFiatBankCardViewModel
  @Injected private var alert: AlertProtocol

  private let disposeBag = DisposeBag()

  static func instantiate(
    viewModel: WithdrawalAddFiatBankCardViewModel? = nil,
    alert: AlertProtocol? = nil)
    -> WithdrawalAddFiatBankCardViewController
  {
    let vc = WithdrawalAddFiatBankCardViewController()
    if let viewModel {
      vc._viewModel.wrappedValue = viewModel
    }

    if let alert {
      vc._alert.wrappedValue = alert
    }

    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  func editNameAction(editable: Bool) {
    editable ? navigateToEditUsername() : showUsernameCannotEditAlert()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

extension WithdrawalAddFiatBankCardViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: .back,
        image: "Close")

    addSubView(from: { [unowned self] in
      WithdrawalAddFiatBankCardView(
        viewModel: self.viewModel,
        tapUserName: { [weak self] in
          self?.editNameAction(editable: $0)
        },
        submitSuccess: { [weak self] in
          self?.showAddBankCardSuccessAlert()
        })
        .environment(\.playerLocale, viewModel.getSupportLocale())
    }, to: view)
  }

  private func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)
  }

  override func handleErrors(_ error: Error) {
    if error is KtoWithdrawalAccountExist {
      alert.show(
        Localize.string("common_tip_title_warm"),
        Localize.string("withdrawal_account_exist"),
        confirm: nil,
        cancel: nil)
    }
    else {
      super.handleErrors(error)
    }
  }

  private func showUsernameCannotEditAlert() {
    alert.show(
      Localize.string("withdrawal_realname_modal_title"),
      Localize.string("withdrawal_realname_modal_content"),
      confirm: nil,
      cancel: nil)
  }

  private func navigateToEditUsername() {
    alert.show(
      Localize.string("withdrawal_bankcard_change_confirm_title"),
      Localize.string("withdrawal_bankcard_change_confirm_content"),
      confirm: {
        self.navigateToAuthorization()
      },
      confirmText: Localize.string("common_moveto"),
      cancel: { })
  }

  private func showAddBankCardSuccessAlert() {
    alert.show(
      Localize.string("withdrawal_setbankaccountsuccess_modal_title"),
      Localize.string("withdrawal_setbankaccountsuccess_modal_content"),
      confirm: { [weak self] in
        self?.popThenToast()
      },
      cancel: nil)
  }

  private func popThenToast() {
    NavigationManagement.sharedInstance.popViewController({ [weak self] in
      self?.showToast(Localize.string("withdrawal_account_added"), barImg: .success)
    })
  }
}
