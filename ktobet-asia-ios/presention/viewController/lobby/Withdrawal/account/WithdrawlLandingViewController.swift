import UIKit
import RxSwift
import SharedBu

class WithdrawlLandingViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalBankLanding"
    private lazy var emptyViewController: WithdrawlEmptyViewController = {
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "WithdrawlEmptyViewController") as! WithdrawlEmptyViewController
        viewController.bankCardType = bankCardType
        self.add(asChildViewController: viewController)
        return viewController
    }()
    private lazy var accountsViewController: WithdrawlAccountsViewController = {
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "WithdrawlAccountsViewController") as! WithdrawlAccountsViewController
        viewController.withdrawalAccounts = accounts
        viewController.cryptoBankCards = cryptoBankCards
        viewController.bankCardType = bankCardType

        self.add(asChildViewController: viewController)
        return viewController
    }()
    fileprivate var viewModel = DI.resolve(WithdrawlLandingViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    var accounts: [WithdrawalAccount]?
    var cryptoBankCards: [CryptoBankCard]?
    var bankCardType: BankCardType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, icon: .back, customAction: #selector(tapBack))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.withdrawalAccounts().subscribe(onSuccess: { [weak self] (accounts) in
            self?.accounts = accounts
            self?.updateView()
        }, onError: { [weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
    }
    
    private func updateView() {
        switch bankCardType {
        case .general:
            if let accounts = accounts, accounts.count > 0 {
                addAccountsView()
            } else {
                // if accounts count = 0, reset WithdrawlAccountsViewController isEditMode to false
                addEmptyView()
            }
        case .crypto:
            if let cryptoBankCards = cryptoBankCards, cryptoBankCards.count > 0 {
                addAccountsView()
            } else {
                addEmptyView()
            }
        default:
            break
        }
    }
    
    private func addAccountsView() {
        remove(asChildViewController: emptyViewController)
        add(asChildViewController: accountsViewController)
    }
    
    private func addEmptyView() {
        accountsViewController.withdrawalAccounts = nil
        remove(asChildViewController: accountsViewController)
        emptyViewController.bankCardType = bankCardType
        add(asChildViewController: emptyViewController)
    }
    
    @objc func tapBack() {
        if let accounts = accounts, accounts.count > 0 {
            accountsViewController.tapBack()
        } else {
            emptyViewController.tapBack()
        }
    }
    
    // MARK: - Helper Methods
    private func add(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
