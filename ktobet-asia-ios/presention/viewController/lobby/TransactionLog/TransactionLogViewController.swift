import UIKit
import RxSwift
import RxDataSources
import SharedBu

class TransactionLogViewController: APPViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dateView: KTODateView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var filterBtn: FilterButton!
    @IBOutlet weak var inComeLabel: UILabel!
    @IBOutlet weak var outComeLabel: UILabel!
    @IBOutlet weak var summaryView: UIView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    let disposeBag = DisposeBag()
    let viewModel = DI.resolve(TransactionLogViewModel.self)!
    let summaryRefresh = PublishSubject<()>()
    var dataSource: RxTableViewSectionedReloadDataSource<SectionModel<String, TransactionLog>>!
    
    private lazy var flow = TranscationFlowController(self, disposeBag: disposeBag)
    private var dateType: DateType = .week()
    private lazy var filterPersenter = TransactionLogPresenter()
    private var curentFilter: [FilterItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("balancelog_title"))
        //Deposit refactor feature兼容舊的流程
        let depositLogViewModel = DI.resolve(DepositLogViewModel.self)!
        depositLogViewModel.recentPaymentLogs.subscribe(onNext: { _ in }).disposed(by: disposeBag)
        //end
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, TransactionLog>>(
            configureCell: { (_, tv, indexPath, element) in
                let cell = tv.dequeueReusableCell(withIdentifier: String(describing: TransactionLogTableViewCell.self)) as! TransactionLogTableViewCell
                cell.setUp(data: element)
                return cell
            }
        )
        
        let tapGesture = UITapGestureRecognizer()
        summaryView.addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind(onNext: {[weak self] _ in
            self?.performSegue(withIdentifier: TransactionLogSummaryViewController.segueIdentifier, sender: nil)
        }).disposed(by: disposeBag)
        
        
        let transactionSummary = summaryRefresh.flatMap {[unowned self] _ in
            self.viewModel.getCashFlowSummary().asObservable()
        }
        
        transactionSummary
            .subscribe {[weak self] cashFlowSummary in
                self?.inComeLabel.text = cashFlowSummary.income.formatString(sign: .signed_)
                self?.outComeLabel.text = cashFlowSummary.outcome.negativeAmount()
            } onError: {[weak self] error in
                self?.handleErrors(error)
            }.disposed(by: disposeBag)
        
        let contentSizeObservable = tableView.rx.observe(CGSize.self, #keyPath(UITableView.contentSize)).asObservable()
        contentSizeObservable.subscribe { size in
            if let height = size.element??.height {
                self.tableViewHeightConstraint.constant = height
            }
        }.disposed(by: disposeBag)
        
        viewModel.pagination.elements
            .catchError({[weak self] error in
                self?.handleErrors(error)
                return Observable.just([])
            })
            .do(onNext: {[weak self] transactionLogs in
                self?.emptyView.isHidden = !transactionLogs.isEmpty
                self?.tableView.isHidden = transactionLogs.isEmpty
            })
            .map { (records) -> [SectionModel<String, TransactionLog>] in
                var sectionModels: [SectionModel<String, TransactionLog>] = []
                let sortedData = records.sorted(by: { $0.date.toDateTimeFormatString() > $1.date.toDateTimeFormatString() })
                let groupDic = Dictionary(grouping: sortedData, by: { String(format: "%02d/%02d/%02d", $0.date.year, $0.date.monthNumber, $0.date.dayOfMonth) })
                let tupleData: [(String, [TransactionLog])] = groupDic.dictionaryToTuple()
                tupleData.forEach{
                    let today = Date().convertdateToUTC().toDateString()
                    let sectionTitle = $0 == today ? Localize.string("common_today") : $0
                    sectionModels.append(SectionModel(model: sectionTitle, items: $1))
                }
                
                return sectionModels.sorted(by: { $0.model > $1.model })
            }.asObservable().bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        scrollView.rx_reachedBottom
            .map{ _ in ()}
            .bind(to: self.viewModel.pagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        dateView.callBackCondition = {[weak self] (dateBegin, dateEnd, dateType) in
            self?.viewModel.from = dateBegin
            self?.viewModel.to = dateEnd
            self?.dateType = dateType
            self?.refreshData()
        }
        
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let bankFilterVC = storyboard.instantiateViewController(withIdentifier: "TransactionFilterViewController") as! TransactionFilterViewController
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
        
        refreshData()
        
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(TransactionLog.self)).bind {[weak self] (indexPath, data) in
            self?.flow.goNext(data)
        }.disposed(by: disposeBag)
        flow.delegate = self
    }
    
    private func refreshData() {
        summaryRefresh.onNext(())
        viewModel.pagination.refreshTrigger.onNext(())
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == TransactionLogSummaryViewController.segueIdentifier {
            if let dest = segue.destination as? TransactionLogSummaryViewController {
                dest.viewModel = self.viewModel
            }
        }
    }
}

extension TransactionLogViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        let label = UILabel()
        header.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -12).isActive = true
        label.textColor = UIColor.whiteFull
        label.font = UIFont(name: "PingFangSC-Medium", size: 16.0)
        label.text = dataSource[section].model
        label.sizeToFit()
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
}

extension TransactionLogViewController: TranscationFlowDelegate {
    
    func displaySportsBookDetail(wagerId: String) {
        viewModel.getSportsBookWagerDetail(wagerId: wagerId).subscribe(onSuccess: { [weak self] (html) in
            guard let alertView = self?.storyboard?.instantiateViewController(withIdentifier: "TransactionHtmlViewController") as? TransactionHtmlViewController else { return }
            alertView.html = html
            alertView.view.backgroundColor = UIColor.black80
            alertView.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            alertView.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            self?.present(alertView, animated: true, completion: nil)
        }, onError: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
}
