import UIKit
import RxSwift
import SharedBu

class WithdrawlLandingViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalBankLanding"
    private lazy var emptyViewController: WithdrawlEmptyViewController = {
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "WithdrawlEmptyViewController") as! WithdrawlEmptyViewController
        self.add(asChildViewController: viewController)
        return viewController
    }()
    private lazy var accountsViewController: WithdrawlAccountsViewController = {
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "WithdrawlAccountsViewController") as! WithdrawlAccountsViewController
        self.add(asChildViewController: viewController)
        return viewController
    }()
    fileprivate var viewModel = DI.resolve(WithdrawlLandingViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    var accounts: [WithdrawalAccount]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, icon: .back, customAction: #selector(tapBack))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateView()
        viewModel.withdrawalAccounts().subscribe(onSuccess: { [weak self] (accounts) in
            self?.accounts = accounts
            self?.updateView()
        }, onError: { [weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
    }
    
    private func updateView() {
        if let accounts = accounts, accounts.count > 0 {
            remove(asChildViewController: emptyViewController)
            accountsViewController.withdrawalAccounts = accounts
            add(asChildViewController: accountsViewController)
        } else {
            // if accounts count = 0, reset WithdrawlAccountsViewController isEditMode to false
            accountsViewController.withdrawalAccounts = nil
            remove(asChildViewController: accountsViewController)
            add(asChildViewController: emptyViewController)
        }
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
