import RxSwift
import sharedbu
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
        guard let updateUrl else { return }

        Single.from(updateUrl)
            .subscribe(
                onSuccess: { url in
                    NavigationManagement.sharedInstance
                        .pushViewController(vc: DepositCryptoWebViewController(url: url.url))
                },
                onFailure: { [weak self] error in
                    self?.handleErrors(error)
                })
            .disposed(by: disposeBag)
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
