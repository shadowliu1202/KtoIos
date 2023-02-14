import RxGesture
import RxSwift
import SharedBu
import UIKit

class CryptoSelectorViewController: LobbyViewController,
                                    SwiftUIConverter
{
  static let segueIdentifier = "toCryptoSelector"
  
  @Injected private var navigator: DepositNavigator
  @Injected private var playerConfig: PlayerConfiguration
  @Injected private var viewModel: CryptoDepositViewModel
  @Injected var localStorageRepo: LocalStorageRepository
  @Injected private var alert: AlertProtocol

  private let disposeBag = DisposeBag()

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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == DepositCryptoViewController.segueIdentifier {
      if let dest = segue.destination as? DepositCryptoViewController {
        dest.url = sender as? String
      }
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
    navigator.toGuidePage(localStorageRepo.getSupportLocale())
  }
  
  func navigateToVideoTutorial() {
    self.present(CryptoVideoTutorialViewController(), animated: true)
  }
  
  func navigateToDepositCryptoVC(_ url: String) {
    navigator.toCryptoWebPage(url: url)
  }
}
