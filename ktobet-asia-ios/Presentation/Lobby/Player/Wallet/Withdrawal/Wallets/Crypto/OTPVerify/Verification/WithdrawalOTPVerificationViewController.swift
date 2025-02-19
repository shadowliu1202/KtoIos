import RxSwift
import sharedbu
import SwiftUI
import UIKit

class WithdrawalOTPVerificationViewController: LobbyViewController {
  @Injected private var viewModel: WithdrawalOTPVerificationViewModel
  @Injected private var alert: AlertProtocol

  private let accountType: sharedbu.AccountType

  private let disposeBag = DisposeBag()

  init(
    viewModel: WithdrawalOTPVerificationViewModel? = nil,
    alert: AlertProtocol? = nil,
    accountType: sharedbu.AccountType)
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

  override func viewDidLoad() {
    super.viewDidLoad()
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
          otpVerifyOnCompleted: { [unowned self] in
            alertVerifyFinishedThenPopToRoot()
          },
          otpResentOnCompleted: { [unowned self] in
            showSendOTPSuccess()
          },
          onErrorRedirect: { [unowned self] in
            handleErrorToRedirect($0)
          })
          .environment(\.playerLocale, viewModel.getSupportLocale())
      }, to: view)
  }

  func showSendOTPSuccess() {
    showToast(Localize.string("common_otp_send_success"), barImg: .success)
  }

  func binding() {
    viewModel.errors()
      .subscribe(onNext: { [unowned self] error in
        handleErrors(error)
      })
      .disposed(by: disposeBag)
  }
  
  private func handleErrorToRedirect(_ error: Error) {
    switch error {
    case let error as WithdrawalDto.VerifyConfirmErrorStatus:
      handleVerifyConfirmError(error)
    case let error as WithdrawalDto.VerifyRequestErrorStatus:
      handleVerifyRequestError(error)
    default:
      assertionFailure("should not reach here.")
    }
  }
  
  private func handleVerifyConfirmError(_ error: WithdrawalDto.VerifyConfirmErrorStatus) {
    switch error {
    case is WithdrawalDto.VerifyConfirmErrorStatusWrongOtp:
      break
    case is WithdrawalDto.VerifyConfirmErrorStatusMaintenance:
      break
    case is WithdrawalDto.VerifyConfirmErrorStatusRetryLimit:
      pushToVerifyFailurePage()
    default: fatalError("should not reach here.")
    }
  }

  private func handleVerifyRequestError(_ error: WithdrawalDto.VerifyRequestErrorStatus) {
    switch error {
    case is WithdrawalDto.VerifyRequestErrorStatusOverDailyLimit:
      var message = ""
      switch accountType {
      case .phone: message = Localize.string("common_sms_otp_exeed_send_limit")
      case .email: message = Localize.string("common_email_otp_exeed_send_limit")
      default: fatalError("should not reach here.")
      }
      
      alertOverLimitThenPushToVerifyFailurePage(message)
    case is WithdrawalDto.VerifyRequestErrorStatusMaintenance:
      var message = ""
      switch accountType {
      case .phone: message = Localize.string("withdrawal_resent_otp_maintenance_phone")
      case .email: message = Localize.string("withdrawal_resent_otp_maintenance_email")
      default: fatalError("should not reach here.")
      }
      
      pushToVerifyFailurePage(message)
    default: fatalError("should not reach here.")
    }
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

  func pushToVerifyFailurePage(_ message: String? = nil) {
    navigationController?
      .pushViewController(
        SharedOTPVerificationFailureViewController(message: message),
        animated: true)
  }

  func alertOverLimitThenPushToVerifyFailurePage(_ message: String) {
    alert
      .show(
        Localize.string("common_tip_title_warm"),
        message,
        confirm: { [weak self] in
          self?.pushToVerifyFailurePage()
        },
        cancel: nil)
  }
}
