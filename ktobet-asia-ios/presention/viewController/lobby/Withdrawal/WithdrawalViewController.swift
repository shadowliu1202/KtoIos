import UIKit
import RxSwift
import SharedBu

class WithdrawalViewController: UIViewController {
    @IBOutlet private weak var withdrawalTodayAmountLimitLabel: UILabel!
    @IBOutlet private weak var withdrawalTodayCountLimitLabel: UILabel!
    @IBOutlet private weak var turnoverRequirementLabel: UILabel!
    @IBOutlet private weak var crpytoWithdrawalRequirementLabel: UILabel!
    @IBOutlet private weak var crpytoWithdrawalAmountLabel: UILabel!
    @IBOutlet private weak var showInfoButton: UIButton!
    @IBOutlet private weak var withdrawView: UIView!
    @IBOutlet private weak var withdrawLabel: UILabel!
    @IBOutlet private weak var crpytoView: UIView!
    @IBOutlet private weak var crpytoLabel: UILabel!
    @IBOutlet private weak var withdrawalRecordNoDataLabel: UILabel!
    @IBOutlet private weak var withdrawalRecordTitleLabel: UILabel!
    @IBOutlet private weak var showAllWithdrawalButton: UIButton!
    @IBOutlet private weak var withdrawalRecordTableView: UITableView!
    @IBOutlet private weak var constraintWithdrawalRecordTableHeight: NSLayoutConstraint!
    private var accounts: [WithdrawalAccount]?
    private var cryptoBankCards: [CryptoBankCard]?
    fileprivate var viewModel = DI.resolve(WithdrawalViewModel.self)!
    fileprivate var bandCardviewModel = DI.resolve(ManageCryptoBankCardViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    private var withdrawalLimits: WithdrawalLimits?
    
    private lazy var dailyLimitAmount: String = "" {
        didSet {
            self.withdrawalTodayAmountLimitLabel.text = Localize.string("cps_daily_limit_widthrawal_amount", dailyLimitAmount)
        }
    }
    private lazy var dailyMaxCount: String = "" {
        didSet {
            self.withdrawalTodayCountLimitLabel.text = Localize.string("cps_daily_limit_widthrawal_times", dailyMaxCount)
        }
    }
    private lazy var turnoverRequirement: Double? = 0 {
        didSet {
            guard let turnoverRequirement = turnoverRequirement else {
                self.turnoverRequirementLabel.text = Localize.string("cps_turnover_requirement")
                return
            }
            let suffix = turnoverRequirement <= 0 ? Localize.string("common_none") : Localize.string("common_requirement", "\(turnoverRequirement.currencyFormatWithoutSymbol(precision: 2))")
            self.turnoverRequirementLabel.text = Localize.string("cps_turnover_requirement") + suffix
        }
    }
    private lazy var crpytoWithdrawalRequirement: Double? = 0 {
        didSet {
            var suffix = Localize.string("common_none")
            var textColor = UIColor.textPrimaryDustyGray
            var icon = UIImage(named: "Tips")
            if let crpytoWithdrawalRequirement = crpytoWithdrawalRequirement, crpytoWithdrawalRequirement > 0 {
                suffix = Localize.string("common_requirement", crpytoWithdrawalRequirement.currencyFormatWithoutSymbol(precision: 8, maximumFractionDigits: 8)+" \(crpytoWithdrawalRequirementCurrencyName())")
                textColor = UIColor.redForDarkFull
                icon = UIImage(named: "iconChevronRightRed7")
                let tap = UITapGestureRecognizer(target: self, action: #selector(switchToCrpytoTransationLog))
                self.crpytoWithdrawalAmountLabel.addGestureRecognizer(tap)
                self.crpytoWithdrawalAmountLabel.isUserInteractionEnabled = true
            }
            self.crpytoWithdrawalAmountLabel.text = suffix
            self.crpytoWithdrawalAmountLabel.textColor = textColor
            self.showInfoButton.setImage(icon, for: .normal)
        }
    }
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("common_withdrawal"))
        initUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        withdrawView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
        crpytoView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        withdrawalLimitationDataBinding()
        recordDataBinding()
        showAllRecordEvenhandler()
        recordDataEvenhandler()
        cryptoWithdrawlDataBinding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disposeBag = DisposeBag()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalRecordDetailViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalRecordDetailViewController {
                dest.detailRecord = sender as? WithdrawalRecord
            }
        } else if segue.identifier == WithdrawlLandingViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawlLandingViewController {
                dest.accounts = accounts
                dest.cryptoBankCards = cryptoBankCards
                dest.bankCardType = sender as? BankCardType
            }
        } else if segue.identifier == CrpytoTransationLogViewController.segueIdentifier {
            if let dest = segue.destination as? CrpytoTransationLogViewController {
                dest.crpytoWithdrawalRequirementAmount = crpytoWithdrawalRequirementAmount()
            }
        }
    }
    
    @IBAction func backToWithdrawal(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        if let vc = segue.source as? WithdrawalRequestConfirmViewController {
            if vc.withdrawalSuccess {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
                toastView.show(on: self.view, statusTip: Localize.string("common_request_submitted"), img: UIImage(named: "Success"))
            }
        }
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        self.dailyLimitAmount = ""
        self.dailyMaxCount = ""
        self.turnoverRequirement = nil
        self.crpytoWithdrawalRequirement = nil
        withdrawalRecordTitleLabel.text = Localize.string("withdrawal_log")
        showAllWithdrawalButton.setTitle(Localize.string("common_show_all"), for: .normal)
        withdrawalRecordNoDataLabel.text = Localize.string("withdrawal_no_records")
        withdrawViewEnable(false)
        withdrawalRecordTableView.isHidden = true
        crpytoViewEnable(false)
    }
    
    fileprivate func cryptoWithdrawlDataBinding() {
        bandCardviewModel.getCryptoBankCards().subscribe {[weak self] (cryptoBankCards) in
            self?.cryptoBankCards = cryptoBankCards
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func withdrawViewEnable(_ enable: Bool) {
        if enable {
            self.withdrawView.alpha = 1
            let withdrawTap = UITapGestureRecognizer(target: self, action: #selector(withdrawTap(_:)))
            self.withdrawView.isUserInteractionEnabled = true
            self.withdrawView.addGestureRecognizer(withdrawTap)
        } else {
            self.withdrawView.alpha = 0.3
            self.withdrawView.isUserInteractionEnabled = false
        }
    }
    
    @objc fileprivate func withdrawTap(_ sender: UITapGestureRecognizer) {
        if let withdrawalLimits = withdrawalLimits, withdrawalLimits.hasCryptoRequirement() {
            Alert.show(Localize.string("cps_cash_withdrawal_lock_title"),
                       Localize.string("cps_cash_withdrawal_lock_desc", String(format: "%.8f", crpytoWithdrawalRequirementAmount()!)),
                       confirm: {
                            self.dismiss(animated: true, completion: nil)
                       }, cancel: nil)
        } else {
            self.performSegue(withIdentifier: WithdrawlLandingViewController.segueIdentifier, sender: BankCardType.general)
        }
    }
    
    private func crpytoViewEnable(_ enable: Bool) {
        if enable {
            self.crpytoView.alpha = 1
            let crpytoTap = UITapGestureRecognizer(target: self, action: #selector(crpytoTap(_:)))
            self.crpytoView.isUserInteractionEnabled = true
            self.crpytoView.addGestureRecognizer(crpytoTap)
        } else {
            self.crpytoView.alpha = 0.3
            self.crpytoView.isUserInteractionEnabled = false
        }
    }
    
    @objc fileprivate func crpytoTap(_ sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: WithdrawlLandingViewController.segueIdentifier, sender: BankCardType.crypto)
    }
    
    fileprivate func withdrawalLimitationDataBinding() {
        viewModel.withdrawalAccounts().subscribe(onSuccess: { [weak self] (accounts) in
            self?.accounts = accounts
        }, onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
        viewModel.getWithdrawalLimitation().subscribe { [weak self] (withdrawalLimits) in
            guard let self = self else { return }
            self.withdrawalLimits = withdrawalLimits
            self.dailyLimitAmount = "\(withdrawalLimits.dailyCurrentCash.amount.currencyFormatWithoutSymbol(precision: 2))"
            self.dailyMaxCount = "\(withdrawalLimits.dailyCurrentCount)"
            self.turnoverRequirement = withdrawalLimits.remainCashTurnover().amount
            self.crpytoWithdrawalRequirement = self.crpytoWithdrawalRequirementAmount()
            self.checkDailyWithdrawalLimit(withdrawalLimits.dailyMaxCash.amount, withdrawalLimits.dailyMaxCount)
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
        
        self.showInfoButton.rx.tap.subscribe(onNext: { [weak self] _ in
            if let amount = self?.crpytoWithdrawalRequirementAmount(), amount > 0 {
                self?.switchToCrpytoTransationLog()
            } else {
                Alert.show(Localize.string("cps_crpyto_withdrawal_requirement_title"),
                           Localize.string("cps_crpyto_withdrawal_requirement_desc"),
                           confirm: {
                                self?.dismiss(animated: true, completion: nil)
                           }, cancel: nil)
            }
        }).disposed(by: self.disposeBag)
    }
    
    @objc private func switchToCrpytoTransationLog() {
        self.performSegue(withIdentifier: CrpytoTransationLogViewController.segueIdentifier, sender: nil)
    }
    
    private func crpytoWithdrawalRequirementCurrencyName() -> String {
        return self.withdrawalLimits?.unresolvedCryptoTurnover().cryptoCurrency.simpleName ?? ""
    }
    
    private func crpytoWithdrawalRequirementAmount() -> Double? {
        return self.withdrawalLimits?.unresolvedCryptoTurnover().cryptoAmount
    }
    
    private func checkDailyWithdrawalLimit(_ amount: Double, _ count: Int32) {
        if amount == 0 || count == 0 {
            self.withdrawViewEnable(false)
            self.crpytoViewEnable(false)
        } else {
            self.withdrawViewEnable(true)
            self.crpytoViewEnable(true)
        }
    }
    
    fileprivate func recordDataBinding() {
        withdrawalRecordTableView.delegate = nil
        withdrawalRecordTableView.dataSource = nil
        let getWithdrawalRecordObservable = viewModel.getWithdrawalRecords().catchError { error in
            self.handleUnknownError(error)
            return Single<[WithdrawalRecord]>.never() }.asObservable().share(replay: 1)
        getWithdrawalRecordObservable.bind(to: withdrawalRecordTableView.rx.items(cellIdentifier: String(describing: WithdrawRecordTableViewCell.self), cellType: WithdrawRecordTableViewCell.self)) {(index, data, cell) in
            cell.setUp(data: data)
        }.disposed(by: disposeBag)
        
        getWithdrawalRecordObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe( onNext: { [weak self] (withdrawalRecord) in
                self?.withdrawalRecordTableView.isHidden = false
                self?.constraintWithdrawalRecordTableHeight.constant = CGFloat(withdrawalRecord.count * 80)
                self?.withdrawalRecordTableView.layoutIfNeeded()
                self?.withdrawalRecordTableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
                self?.withdrawalRecordTableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
                if withdrawalRecord.count == 0 {
                    self?.withdrawalRecordNoDataLabel.isHidden = false
                    self?.withdrawalRecordTableView.isHidden = true
                    self?.showAllWithdrawalButton.isHidden = true
                } else {
                    self?.withdrawalRecordNoDataLabel.isHidden = true
                    self?.withdrawalRecordTableView.isHidden = false
                    self?.showAllWithdrawalButton.isHidden = false
                }
            }).disposed(by: disposeBag)
    }
    
    fileprivate func showAllRecordEvenhandler() {
        showAllWithdrawalButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.performSegue(withIdentifier: WithdrawalRecordViewController.segueIdentifier, sender: nil)
        }).disposed(by: disposeBag)
    }
    
    fileprivate func recordDataEvenhandler() {
        Observable.zip(withdrawalRecordTableView.rx.itemSelected, withdrawalRecordTableView.rx.modelSelected(WithdrawalRecord.self)).bind {[weak self] (indexPath, data) in
            self?.performSegue(withIdentifier: WithdrawalRecordDetailViewController.segueIdentifier, sender: data)
            self?.withdrawalRecordTableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
}


enum BankCardType: String {
    case crypto = "crypto"
    case general = "general"
}
