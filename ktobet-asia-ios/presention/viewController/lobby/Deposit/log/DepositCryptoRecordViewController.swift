import UIKit
import SwiftUI
import SharedBu

class DepositCryptoRecordViewController: LobbyViewController,
                                            SwiftUIConverter {

    private let viewModel: DepositCryptoRecordViewModel
    
    init(viewModel: DepositCryptoRecordViewModel) {
        self.viewModel = viewModel
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
                submitTransactionIdOnClick: {
                    self.navigateToDepositCryptoVC($0)
                },
                viewModel: self.viewModel
            )
        }, to: view)
    }
}
