import UIKit
import RxSwift
import SharedBu

class WithdrawalRequestConfirmViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalRequestConfirm"
    @IBOutlet private weak var withdrawalAmountLabel: UILabel!
    @IBOutlet private weak var withdrawalTodayCountLimitLabel: UILabel!
    @IBOutlet private weak var withdrawalTodayAmountLimitLabel: UILabel!
    @IBOutlet private weak var confirmButton: UIButton!
    
    private var viewModel = DI.resolve(WithdrawalRequestViewModel.self)!
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    var account: WithdrawalAccount!
    var amount: String!
    var withdrawalLimits: WithdrawalLimits!
    var withdrawalSuccess: Bool = false
    
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
    }
    
    private func initUI() {
        withdrawalAmountLabel.text = amount
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        withdrawalTodayCountLimitLabel.text = Localize.string("common_times_count","\(withdrawalLimits.dailyMaxCount - 1)")
        withdrawalTodayAmountLimitLabel.text = "\((withdrawalLimits.dailyMaxCash.amount - amount.currencyAmountToDouble()!).currencyFormatWithoutSymbol(precision: 2))"
        self.startActivityIndicator(activityIndicator: self.activityIndicator)
        self.viewModel.isRealNameEditable().subscribe { [weak self] _ in
            guard let self = self else { return }
            self.stopActivityIndicator(activityIndicator: self.activityIndicator)
        } onError: {[weak self] (error) in
            guard let self = self else { return }
            self.stopActivityIndicator(activityIndicator: self.activityIndicator)
            self.handleUnknownError(error)
        }.disposed(by: self.disposeBag)
        
        confirmButton.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            if self.viewModel.relayNameEditable {
                Alert.show( String(format: Localize.string("withdrawal_success_confirm_title"), self.account.accountName) , Localize.string("withdrawal_success_confirm_content"), confirm: {[weak self] in
                    self?.sendWithdrawalRequest()
                }, cancel: nil)
            } else {
                self.sendWithdrawalRequest()
            }
        }).disposed(by: self.disposeBag)
    }
    
    private func sendWithdrawalRequest() {
        guard let amount = Double(amount.replacingOccurrences(of: ",", with: "")) else { return }
        self.viewModel.sendWithdrawalRequest(playerBankCardId: self.account.playerBankCardId, cashAmount: CashAmount(amount: amount)).subscribe { (transactionId) in
            self.withdrawalSuccess = transactionId != ""
            self.performSegue(withIdentifier: "unwindToWithdrawal", sender: nil)
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: self.disposeBag)
    }
}
