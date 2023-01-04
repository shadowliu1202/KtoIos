import UIKit
import SwiftUI
import SharedBu

class DepositCryptoRecordViewController: LobbyViewController,
                                            SwiftUIConverter {

    @Injected var viewModel: DepositCryptoRecordViewModel
    @Injected private var playerConfig: PlayerConfiguration
    private let transactionId: String
    
    init(transactionId: String) {
        self.transactionId = transactionId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    private func navigateToDepositCryptoVC(_ updateUrl: SingleWrapper<HttpUrl>?) {
        guard let depositCryptoViewController = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "DepositCryptoViewController") as? DepositCryptoViewController else { return }
        depositCryptoViewController.updateUrl = updateUrl
        NavigationManagement.sharedInstance.pushViewController(vc: depositCryptoViewController)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

private extension DepositCryptoRecordViewController {
    
    func setupUI() {
        addSubView(from: { [unowned self] in
            DepositCryptoRecordView(
                playerConfig: self.playerConfig,
                submitTransactionIdOnClick: {
                    self.navigateToDepositCryptoVC($0)
                },
                transactionId: self.transactionId,
                viewModel: self.viewModel
            )
        }, to: view)
    }
}
