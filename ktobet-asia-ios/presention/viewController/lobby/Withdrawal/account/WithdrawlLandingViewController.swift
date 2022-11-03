import UIKit
import RxSwift
import SharedBu

class WithdrawlLandingViewController: LobbyViewController {
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
    fileprivate var viewModel = Injectable.resolve(WithdrawlLandingViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var accountsCount: Int {
        switch bankCardType {
        case .general:
            return accounts.count
        case .crypto:
            return cryptoBankCards.count
        case .none:
            fatalError("Should net reach here.")
        }
    }
    lazy var accounts: [FiatBankCard] = []
    lazy var cryptoBankCards: [CryptoBankCard] = []
    var bankCardType: BankCardType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAccountsView()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(tapBack))
        Logger.shared.info("", tag: "KTO-876")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch bankCardType {
        case .general:
            Logger.shared.info("general", tag: "KTO-876")
            viewModel.withdrawalAccounts().subscribe(onSuccess: { [weak self] (accounts) in
                self?.accounts = accounts
                self?.updateWithdrawAccountsView()
            }, onFailure: { [weak self] (error) in
                self?.handleErrors(error)
            }).disposed(by: disposeBag)
        case .crypto:
            Logger.shared.info("crypto", tag: "KTO-876")
            viewModel.getCryptoBankCards().subscribe {[weak self] (cryptoBankCards) in
                self?.cryptoBankCards = cryptoBankCards
                self?.updateWithdrawAccountsView()
            } onFailure: { [weak self] (error) in
                self?.handleErrors(error)
            }.disposed(by: disposeBag)
        case .none:
            fatalError("Should net reach here.")
        }
    }
    
    private func updateWithdrawAccountsView() {
        if accountsCount > 0 {
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
    
    override func handleErrors(_ error: Error) {
        super.handleErrors(error)
        self.accountsViewController.footerView.isHidden = true
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
