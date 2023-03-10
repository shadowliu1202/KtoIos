import RxSwift
import SharedBu
import SwiftUI
import UIKit

class DepositCryptoRecordDetailViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected var viewModel: DepositCryptoRecordDetailViewModel
  @Injected private var playerConfig: PlayerConfiguration

  private let transactionId: String
  private let disposeBag = DisposeBag()

  init(transactionId: String) {
    self.transactionId = transactionId
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  private func navigateToDepositCryptoVC(_ updateUrl: SingleWrapper<HttpUrl>?) {
    guard
      let depositCryptoViewController = UIStoryboard(name: "Deposit", bundle: nil)
        .instantiateViewController(withIdentifier: "DepositCryptoViewController") as? DepositCryptoViewController,
      let updateUrl
    else { return }

    Single.from(updateUrl)
      .subscribe(
        onSuccess: { url in
          depositCryptoViewController.url = url.url
          NavigationManagement.sharedInstance.pushViewController(vc: depositCryptoViewController)
        },
        onFailure: { [weak self] error in
          self?.handleErrors(error)
        })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

extension DepositCryptoRecordDetailViewController {
  private func setupUI() {
    addSubView(from: { [unowned self] in
      DepositCryptoRecordDetailView(
        playerConfig: self.playerConfig,
        submitTransactionIdOnClick: {
          self.navigateToDepositCryptoVC($0)
        },
        transactionId: self.transactionId,
        viewModel: self.viewModel)
    }, to: view)
  }
}
