import UIKit
import RxSwift
import SharedBu

class WithdrawlLandingViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalBankLanding"
    static let unwindSegue = "unwindsegueWithdrawalLanding"

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
    fileprivate var accountsCount = 0
    var accounts: [WithdrawalAccount]?
    var cryptoBankCards: [CryptoBankCard]?
    var bankCardType: BankCardType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, icon: .back, customAction: #selector(tapBack))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch bankCardType {
        case .general:
            viewModel.withdrawalAccounts().subscribe(onSuccess: { [weak self] (accounts) in
                self?.accounts = accounts
                self?.accountsCount = accounts.count
                self?.updateView(accountCount: accounts.count)
            }, onError: { [weak self] (error) in
                self?.handleUnknownError(error)
            }).disposed(by: disposeBag)
        case .crypto:
            viewModel.getCryptoBankCards().subscribe {[weak self] (cryptoBankCards) in
                self?.cryptoBankCards = cryptoBankCards
                self?.accountsCount = cryptoBankCards.count
                self?.updateView(accountCount: cryptoBankCards.count)
            } onError: { (error) in
                self.handleUnknownError(error)
            }.disposed(by: disposeBag)

        default:
            break
        }
    }
    
    private func updateView(accountCount: Int) {
        if accountCount > 0 {
            addAccountsView()
        } else {
            addEmptyView()
        }
    }
    
    private func addAccountsView() {
        remove(asChildViewController: emptyViewController)
        accountsViewController.withdrawalAccounts = accounts
        accountsViewController.cryptoBankCards = cryptoBankCards
        add(asChildViewController: accountsViewController)
    }
    
    private func addEmptyView() {
        accountsViewController.withdrawalAccounts = nil
        remove(asChildViewController: accountsViewController)
        emptyViewController.bankCardType = bankCardType
        add(asChildViewController: emptyViewController)
    }
    
    @objc func tapBack() {
        if accountsCount > 0 {
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
    
    @IBAction func unwindsegueWithdrawalLanding(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        accountsViewController.isEditMode = false
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
