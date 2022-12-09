import UIKit
import RxSwift
import RxDataSources
import SharedBu
import RxGesture

class TransactionLogViewController: LobbyViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dateView: KTODateView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var filterBtn: FilterButton!
    @IBOutlet weak var inComeLabel: UILabel!
    @IBOutlet weak var outComeLabel: UILabel!
    @IBOutlet weak var summaryView: UIView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @Injected private (set) var viewModel: TransactionLogViewModel
    
    private lazy var flow = TranscationFlowController(self, disposeBag: disposeBag)
    private var dateType: DateType = .week()
    
    private lazy var filterPersenter = TransactionLogPresenter()
    private var curentFilter: [FilterItem]?
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        binding()
        
        refreshData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TransactionLogSummaryViewController.segueIdentifier {
            if let dest = segue.destination as? TransactionLogSummaryViewController {
                dest.viewModel = self.viewModel
            }
        }
    }
    
    override func handleErrors(_ error: Error) {
        switch error {
        case is PlayerWagerDetailUnderMaintain:
            displayAlert(Localize.string("common_notification"), Localize.string("balancelog_wager_detail_is_maintain"))
            
        case is PlayerWagerDetailNotFound:
            displayAlert(Localize.string("common_notification"), Localize.string("balancelog_wager_sync_unfinished"))
            
        default:
            super.handleErrors(error)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - UI

private extension TransactionLogViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(
            vc: self,
            title: Localize.string("balancelog_title")
        )
        
        dateView.callBackCondition = { [weak self] (dateBegin, dateEnd, dateType) in
            self?.viewModel.from = dateBegin ?? .init()
            self?.viewModel.to = dateEnd ?? .init()
            self?.dateType = dateType
            self?.refreshData()
        }
        
        let bankFilterVC = TransactionFilterViewController.initFrom(storyboard: "Filter")
        
        filterBtn.set(filterPersenter)
            .set(curentFilter)
            .setGotoFilterVC(vc: bankFilterVC)
            .set { [weak self] (items) in
                guard let self = self else { return }
                self.curentFilter = items as? [TransactionItem]
                self.filterBtn.set(self.curentFilter)
                self.filterBtn.setTitle(Array(items.dropFirst()))
                let balanceLogFilterType = self.filterPersenter.getConditionStatus(items as! [TransactionLogItem])
                self.viewModel.balanceLogFilterType = balanceLogFilterType.rawValue
                self.refreshData()
            }
        
        flow.delegate = self
    }
    
    func binding() {
        summaryView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                self?.performSegue(
                    withIdentifier: TransactionLogSummaryViewController.segueIdentifier,
                    sender: nil
                )
            })
            .disposed(by: disposeBag)
        
        viewModel.summary
            .subscribe(onNext: { [weak self] cashFlowSummary in
                self?.inComeLabel.text = cashFlowSummary.income.formatString(sign: .signed_)
                self?.outComeLabel.text = cashFlowSummary.outcome.formatString(sign: .signed_)
            })
            .disposed(by: disposeBag)
        
        let dataSource = RxTableViewSectionedReloadDataSource<TransactionLogViewModel.Section>(
            configureCell: { (_, tableView, indexPath, element) in
                let cell: TransactionLogTableViewCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setUp(data: element)
                return cell
            }
        )
        
        viewModel.sections
            .do(onNext: { [weak self] transactionLogs in
                self?.emptyView.isHidden = !transactionLogs.isEmpty
                self?.tableView.isHidden = transactionLogs.isEmpty
            })
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.errors()
            .subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
                
        tableView.rx
            .observe(\.contentSize)
            .subscribe { [unowned self] size in
                if let height = size.element?.height {
                    self.tableViewHeightConstraint.constant = height
                }
            }
            .disposed(by: disposeBag)
        
        scrollView.rx.reachedBottom
            .bind(to: self.viewModel.pagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        tableView.rx
            .modelSelected(TransactionLog.self)
            .bind { [weak self] data in
                self?.flow.goNext(data)
            }
            .disposed(by: disposeBag)
        
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        /// Deposit refactor feature兼容舊的流程
        let depositLogViewModel = Injectable.resolve(DepositLogViewModel.self)!
        depositLogViewModel.recentPaymentLogs.subscribe(onNext: { _ in }).disposed(by: disposeBag)
    }
    
    func refreshData() {
        viewModel.summaryRefreshTrigger.onNext(())
        viewModel.pagination.refreshTrigger.onNext(())
    }
    
    func displayAlert(_ tilte: String, _ msg: String) {
        Alert.shared.show(tilte, msg, confirm: {}, cancel: nil)
    }
}

// MARK: - UITableViewDelegate

extension TransactionLogViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        let label = UILabel()
        
        header.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12).isActive = true
        label.textColor = UIColor.whitePure
        label.font = UIFont(name: "PingFangSC-Medium", size: 16.0)
        label.text = viewModel.section(at: section)?.model
        label.sizeToFit()
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}

// MARK: - TranscationFlowDelegate

extension TransactionLogViewController: TranscationFlowDelegate {
    
    func displaySportsBookDetail(wagerId: String) {
        viewModel
            .getSportsBookWagerDetail(wagerId: wagerId)
            .subscribe(onSuccess: { [weak self] (html) in
                let alertView = TransactionHtmlViewController.initFrom(storyboard: "TransactionLog")
                alertView.html = html
                alertView.view.backgroundColor = UIColor.black131313.withAlphaComponent(0.8)
                alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                self?.present(alertView, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}
