import UIKit
import RxSwift
import share_bu

class WithdrawalViewController: UIViewController {
    @IBOutlet private weak var withdrawalTitleLabel: UILabel!
    @IBOutlet private weak var withdrawalTodayCountLimitLabel: UILabel!
    @IBOutlet private weak var withdrawalTodayAmountLimitLabel: UILabel!
    @IBOutlet private weak var showInfoButton: UIButton!
    @IBOutlet private weak var withdrawView: UIView!
    @IBOutlet private weak var withdrawLabel: UILabel!
    @IBOutlet private weak var withdrawalRecordNoDataLabel: UILabel!
    @IBOutlet private weak var withdrawalRecordTitleLabel: UILabel!
    @IBOutlet private weak var showAllWithdrawalButton: UIButton!
    @IBOutlet private weak var withdrawalRecordTableView: UITableView!
    @IBOutlet private weak var constraintWithdrawalRecordTableHeight: NSLayoutConstraint!
    private var accounts: [WithdrawalAccount]?
    fileprivate var viewModel = DI.resolve(WithdrawalViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        withdrawalLimitationDataBinding()
        recordDataBinding()
        showAllRecordEvenhandler()
        recordDataEvenhandler()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disposeBag = DisposeBag()
        NavigationManagement.sharedInstance.removeViewControllers(vcId: "WithdrawalNavigation")
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
        withdrawalTitleLabel.text = Localize.string("common_withdrawal")
        withdrawalTodayCountLimitLabel.text = Localize.string("withdrawal_dailywithdrawalcount")
        withdrawalTodayAmountLimitLabel.text = Localize.string("withdrawal_dailywithdrawalamount")
        withdrawLabel.text = Localize.string("withdrawal_start")
        withdrawalRecordTitleLabel.text = Localize.string("withdrawal_log")
        showAllWithdrawalButton.setTitle(Localize.string("common_show_all"), for: .normal)
        withdrawalRecordNoDataLabel.text = Localize.string("withdrawal_no_records")
        withdrawViewEnable(false)
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
        self.performSegue(withIdentifier: WithdrawlLandingViewController.segueIdentifier, sender: nil)
    }
    
    fileprivate func withdrawalLimitationDataBinding() {
        viewModel.withdrawalAccounts().subscribe(onSuccess: { [weak self] (accounts) in
            self?.accounts = accounts
            self?.withdrawViewEnable(true)
        }, onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
        viewModel.getWithdrawalLimitation().subscribe { [weak self] (withdrawalLimits) in
            guard let self = self else { return }
            self.withdrawalTodayCountLimitLabel.text = "\(Localize.string("withdrawal_dailywithdrawalcount"))\(withdrawalLimits.dailyMaxCount)\(Localize.string("common_times_count"))"
            self.withdrawalTodayAmountLimitLabel.text = "\(Localize.string("withdrawal_dailywithdrawalamount"))\(withdrawalLimits.dailyMaxCash.amount.currencyFormatWithoutSymbol(precision: 2))"
            self.showInfoButton.rx.tap.subscribe(onNext: {
                Alert.show(Localize.string("withdrawal_quota_title"),
                           String(format: Localize.string("withdrawal_quota_content"), String(withdrawalLimits.dailyCurrentCount), withdrawalLimits.dailyCurrentCash.amount.currencyFormatWithoutSymbol(precision: 2)), confirm: nil, cancel: nil)
            }).disposed(by: self.disposeBag)
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func recordDataBinding() {
        let getWithdrawalRecordObservable = viewModel.getWithdrawalRecords().asObservable()
        getWithdrawalRecordObservable.bind(to: withdrawalRecordTableView.rx.items(cellIdentifier: String(describing: WithdrawRecordTableViewCell.self), cellType: WithdrawRecordTableViewCell.self)) {(index, data, cell) in
            cell.setUp(data: data)
        }.disposed(by: disposeBag)
        
        getWithdrawalRecordObservable
            .subscribeOn(MainScheduler.instance)
            .subscribe { [weak self] (withdrawalRecord) in
                self?.constraintWithdrawalRecordTableHeight.constant = CGFloat(withdrawalRecord.count * 80)
                self?.withdrawalRecordTableView.layoutIfNeeded()
                self?.withdrawalRecordTableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
                self?.withdrawalRecordTableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
                if withdrawalRecord.count == 0 {
                    self?.withdrawalRecordNoDataLabel.isHidden = false
                    self?.withdrawalRecordTableView.isHidden = true
                } else {
                    self?.withdrawalRecordNoDataLabel.isHidden = true
                    self?.withdrawalRecordTableView.isHidden = false
                }
            } onError: { (error) in
                self.handleUnknownError(error)
            }.disposed(by: disposeBag)
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
