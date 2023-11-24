import RxGesture
import RxSwift
import sharedbu
import UIKit

class CryptoSelectorViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var playerConfig: PlayerConfiguration
  @Injected private var alert: AlertProtocol
  @Injected private var localStorageRepo: LocalStorageRepository
  @Injected private var viewModel: CryptoDepositViewModel

  private let disposeBag = DisposeBag()

  init(
    localStorageRepo: LocalStorageRepository? = nil,
    viewModel: CryptoDepositViewModel? = nil,
    alert: AlertProtocol? = nil)
  {
    if let localStorageRepo {
      self._localStorageRepo.wrappedValue = localStorageRepo
    }

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

  override func handleErrors(_ error: Error) {
    if error is PlayerDepositCountOverLimit {
      self.notifyTryLaterAndPopBack()
    }
    else {
      super.handleErrors(error)
    }
  }
}

extension CryptoSelectorViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back)

    addSubView(
      from: { [unowned self] in
        CryptoSelectView(
          viewModel: self.viewModel,
          playerConfig: playerConfig,
          userGuideOnTap: {
            self.navigateToGuide()
          },
          tutorialOnTap: {
            self.navigateToVideoTutorial()
          },
          submitButtonOnSuccess: {
            self.navigateToDepositCryptoVC($0.url)
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

  private func notifyTryLaterAndPopBack() {
    alert.show(
      nil,
      Localize.string("deposit_notify_request_later"),
      confirm: {
        NavigationManagement.sharedInstance.popViewController()
      },
      cancel: nil)
  }

  func navigateToGuide() {
    switch localStorageRepo.getSupportLocale() {
    case is SupportLocale.China:
      navigationController?
        .pushViewController(
          CryptoGuideViewController.initFrom(storyboard: "Deposit"),
          animated: true)

    case is SupportLocale.Vietnam:
      fallthrough

    default:
      navigationController?
        .pushViewController(
          CryptoGuideVNDViewController(),
          animated: true)
    }
  }

  func navigateToVideoTutorial() {
    self.present(CryptoVideoTutorialViewController(), animated: true)
  }

  func navigateToDepositCryptoVC(_ url: String) {
    navigationController?
      .pushViewController(
        DepositCryptoWebViewController(url: url),
        animated: true)
  }
}
