import RxSwift
import sharedbu
import SwiftUI
import UIKit

class WithdrawalCreateCryptoAccountViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var viewModel: WithdrawalCreateCryptoAccountViewModel
  @Injected private var alert: AlertProtocol

  private let disposeBag = DisposeBag()

  init(
    viewModel: WithdrawalCreateCryptoAccountViewModel? = nil,
    alert: AlertProtocol? = nil)
  {
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

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    binding()
  }
}

// MARK: - UI

extension WithdrawalCreateCryptoAccountViewController {
  func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: .back,
        image: "Close")

    addSubView(
      from: {
        WithdrawalCreateCryptoAccountView(
          viewModel: viewModel,
          readQRCodeButtonOnTap: { [weak self] in
            self?.pushToImagePicker()
          },
          createAccountOnSuccess: { [weak self] bankCardID in
            self?.showAlertThenPushToVerifyPage(bankCardID)
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
}

// MARK: - Navigation

extension WithdrawalCreateCryptoAccountViewController {
  func showAlertThenPushToVerifyPage(_ bankCardID: String) {
    alert
      .show(
        Localize.string("profile_safety_verification_title"),
        Localize.string("cps_security_alert"),
        confirm: { [weak self] in
          self?.navigationController?
            .pushViewController(
              WithdrawalOTPVerifyMethodSelectViewController(bankCardID: bankCardID),
              animated: true)
        },
        cancel: nil)
  }

  func pushToImagePicker() {
    let imagePickerView = ImagePickerViewController.initFrom(storyboard: "ImagePicker")

    imagePickerView.isHiddenFooterView = true
    imagePickerView.cameraImage = UIImage(named: "Scan")
    imagePickerView.cameraText = Localize.string("cps_scan")
    imagePickerView.cameraType = .qrCode

    imagePickerView.completion = { [weak self] images in
      NavigationManagement.sharedInstance.popViewController()

      self?.viewModel
        .readQRCode(image: images.first, onFailure: { [weak self] in
          self?.alert
            .show(
              Localize.string("cps_qr_code_read_fail"),
              Localize.string("cps_qr_code_read_fail_content"),
              confirm: nil,
              cancel: nil,
              tintColor: UIColor.primaryDefault)
        })
    }

    imagePickerView.qrCodeCompletion = { [weak self] accountAddress in
      if let viewControllers = self?.navigationController?.viewControllers {
        for controller in viewControllers {
          if controller.isKind(of: WithdrawalCreateCryptoAccountViewController.self) {
            NavigationManagement.sharedInstance.popViewController(nil, to: controller)
          }
        }
      }

      self?.viewModel.accountAddress = accountAddress
    }

    navigationController?.pushViewController(imagePickerView, animated: true)
  }
}
