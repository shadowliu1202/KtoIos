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
        self.addViewWithFrames(asChildViewController: viewController)
        return viewController
    }()
    private lazy var accountsViewController: WithdrawlAccountsViewController = {
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        var viewController = storyboard.instantiateViewController(withIdentifier: "WithdrawlAccountsViewController") as! WithdrawlAccountsViewController
        viewController.withdrawalAccounts = accounts
        viewController.cryptoBankCards = cryptoBankCards
        viewController.bankCardType = bankCardType

        self.addViewWithFrames(asChildViewController: viewController)
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
                self?.updateWithdrawAccountsView(according: accounts.count)
            }, onError: { [weak self] (error) in
                self?.handleUnknownError(error)
            }).disposed(by: disposeBag)
        case .crypto:
            viewModel.getCryptoBankCards().subscribe {[weak self] (cryptoBankCards) in
                self?.cryptoBankCards = cryptoBankCards
                self?.accountsCount = cryptoBankCards.count
                self?.updateWithdrawAccountsView(according: cryptoBankCards.count)
            } onError: { (error) in
                self.handleUnknownError(error)
            }.disposed(by: disposeBag)

        default:
            break
        }
    }
    
    private func updateWithdrawAccountsView(according accountCount: Int) {
        if accountCount > 0 {
            setAccountsView()
        } else {
            setEmptyView()
        }
    }
    
    private func setAccountsView() {
        emptyViewController.removeViewReference()
        accountsViewController.withdrawalAccounts = accounts
        accountsViewController.cryptoBankCards = cryptoBankCards
        addViewWithFrames(asChildViewController: accountsViewController)
    }
    
    private func setEmptyView() {
        accountsViewController.withdrawalAccounts = nil
        accountsViewController.removeViewReference()
        emptyViewController.bankCardType = bankCardType
        addViewWithFrames(asChildViewController: emptyViewController)
    }
    
    @objc func tapBack() {
        if accountsCount > 0 {
            accountsViewController.tapBack()
        } else {
            emptyViewController.tapBack()
        }
    }
    
    // MARK: - Helper Methods
    private func addViewWithFrames(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    @IBAction func unwindsegueWithdrawalLanding(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        accountsViewController.isEditMode = false
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}


extension UIViewController {
    func removeViewReference() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
}
