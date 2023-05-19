import RxSwift
import SharedBu
import SwiftUI
import UIKit

class WithdrawalOTPVerificationViewController:
  LobbyViewController &
  SwiftUIConverter
{
  @Injected private var viewModel: WithdrawalOTPVerificationViewModel
  @Injected private var alert: AlertProtocol

  private let accountType: SharedBu.AccountType

  private let disposeBag = DisposeBag()

  init(
    viewModel: WithdrawalOTPVerificationViewModel? = nil,
    alert: AlertProtocol? = nil,
    accountType: SharedBu.AccountType)
  {
    if let viewModel {
      self._viewModel.wrappedValue = viewModel
    }

    if let alert {
      self._alert.wrappedValue = alert
    }

    self.accountType = accountType

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

    setupUI()
    binding()

    showSendOTPSuccess()
  }

  @objc
  func askAbortProcess() {
    alert
      .show(
        Localize.string("common_close_setting_hint"),
        Localize.string("cps_close_otp_verify_hint"),
        confirm: {
          NavigationManagement.sharedInstance.popToRootViewController(nil)
        },
        cancel: { })
  }
}

// MARK: - UI

extension WithdrawalOTPVerificationViewController {
  func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: .close,
        action: #selector(askAbortProcess))

    addSubView(
      from: {
        WithdrawalOTPVerificationView(
          viewModel: viewModel,
          accountType: accountType,
          otpVerifyOnCompleted: { [weak self] in
            self?.alertVerifyFinishedThenPopToRoot()
          },
          otpVerifyOnErrorRedirect: { [weak self] in
            self?.pushToVerifyFailurePage()
          },
          otpResentOnCompleted: { [weak self] in
            self?.showSendOTPSuccess()
          },
          otpResentOnErrorRedirect: { [weak self] error in
            guard let self else { return }

            switch error {
            case .overdailylimit:
              self.alertOverLimitThenPushToVerifyFailurePage()

            case .maintenance:
              break

            default:
              fatalError("should not reach here.")
            }
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

  func showSendOTPSuccess() {
    showToast(Localize.string("common_otp_send_success"), barImg: .success)
  }
}

// MARK: - Navigation

extension WithdrawalOTPVerificationViewController {
  func alertVerifyFinishedThenPopToRoot() {
    alert
      .show(
        Localize.string("common_verify_finished"),
        Localize.string("cps_verify_hint"),
        confirm: { [weak self] in
          self?.navigationController?.popToRootViewController(animated: true)
        },
        cancel: nil)
  }

  func pushToVerifyFailurePage() {
    navigationController?
      .pushViewController(
        SharedOTPVerificationFailureViewController(),
        animated: true)
  }

  func alertOverLimitThenPushToVerifyFailurePage() {
    alert
      .show(
        Localize.string("common_tip_title_warm"),
        Localize.string("common_email_otp_exeed_send_limit"),
        confirm: { [weak self] in
          self?.pushToVerifyFailurePage()
        },
        cancel: nil)
  }
}
