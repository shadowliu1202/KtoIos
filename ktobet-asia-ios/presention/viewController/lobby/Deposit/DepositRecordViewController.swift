import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import share_bu

class DepositRecordViewController: UIViewController {
    static let segueIdentifier = "toAllRecordSegue"
    
    @IBOutlet private weak var dateView: UIView!
    @IBOutlet private weak var filterBtn: FilterButton!
    @IBOutlet private weak var depositRecordTitle: UILabel!
    @IBOutlet private weak var depositTotalTitle: UILabel!
    @IBOutlet private weak var depositTotalAmount: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    private lazy var filterPersenter = DepositPresenter()
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var isLoading = false
    fileprivate var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    fileprivate var curentFilter: [FilterItem]?
    fileprivate var depositDateType: DateType = .week()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        getDepositRecord()
        recordDataHandler()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getDepositSummary()
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        depositRecordTitle.text = Localize.string("deposit_log")
        depositTotalTitle.text = Localize.string("deposit_summary")
        dateView.layer.cornerRadius = 8
        dateView.layer.masksToBounds = true
        dateView.layer.borderWidth = 1
        dateView.layer.borderColor = UIColor.textPrimaryDustyGray.cgColor
        tableView.delegate = self
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.toDate))
        dateView.addGestureRecognizer(gesture)
        filterBtn.set(filterPersenter)
            .set(curentFilter)
            .set { [weak self] (items) in
                guard let `self` = self else { return }
                self.curentFilter = items as? [TransactionItem]
                self.filterBtn.set(self.curentFilter)
                let status: [TransactionStatus] = self.filterPersenter.getConditionStatus(items as! [TransactionItem])
                self.viewModel.status = status
        }
    }
    
    fileprivate func getDepositRecord() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, DepositRecord>>(
            configureCell: { (_, tv, indexPath, element) in
                let cell = tv.dequeueReusableCell(withIdentifier: String(describing: DepositRecordTableViewCell.self)) as! DepositRecordTableViewCell
                cell.setUp(data: element)
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
        
        viewModel.pagination.elements.map { (records) -> [SectionModel<String, DepositRecord>] in
            var sectionModels: [SectionModel<String, DepositRecord>] = []
            let sortedData = records.sorted(by: { $0.createdDate.formatDateToStringToSecond() > $1.createdDate.formatDateToStringToSecond() })
            let groupDic = Dictionary(grouping: sortedData, by: { String(format: "%02d/%02d/%02d", $0.groupDay.year, $0.groupDay.monthNumber, $0.groupDay.dayOfMonth) })
            let tupleData: [(String, [DepositRecord])] = groupDic.dictionaryToTuple()
            tupleData.forEach{
                let today = Date().convertdateToUTC().formatDateToStringToDay()
                let sectionTitle = $0 == today ? Localize.string("common_today") : $0
                sectionModels.append(SectionModel(model: sectionTitle, items: $1))
            }
            
            return sectionModels.sorted(by: { $0.model > $1.model })
        }.asObservable().bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)

        
        rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in () }
            .bind(to: viewModel.pagination.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx_reachedBottom
            .map{ _ in ()}
            .bind(to: self.viewModel.pagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        viewModel.pagination.loading.asObservable()
            .bind(to: isLoading(for: self.view))
            .disposed(by: disposeBag)
                
    }
    
    fileprivate func recordDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(DepositRecord.self)).bind {(indexPath, data) in
            self.performSegue(withIdentifier: DepositRecordDetailViewController.segueIdentifier, sender: data)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func getDepositSummary() {
        viewModel.getCashLogSummary(balanceLogFilterType: 1).subscribe { (data) in
            self.depositTotalAmount.text = data["depositAmount"]?.currencyFormatWithoutSymbol(precision: 2) ?? "0.00"
        } onError: { (error) in
            self.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func isLoading(for view: UIView) -> AnyObserver<Bool> {
        return Binder(view, binding: { (hud, isLoading) in
            switch isLoading {
            case true:
                self.activityIndicator.startAnimating()
            case false:
                self.activityIndicator.stopAnimating()
                break
            }
        }).asObserver()
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DateViewController.segueIdentifier {
            if let dest = segue.destination as? DateViewController {
                dest.conditionCallbck = {[weak self] (dateType) in
                    DispatchQueue.main.async {
                        let dateBegin: Date?
                        let dateEnd: Date?
                        switch dateType {
                        case .day(let day):
                            self?.dateLabel.text = day.formatDateToStringToMonth()
                            dateBegin = day
                            dateEnd = day
                        case .week(let fromDate, let toDate):
                            self?.dateLabel.text = Localize.string("common_last7day")
                            dateBegin = fromDate
                            dateEnd = toDate
                        case .month(let fromDate, let toDate):
                            dateBegin = fromDate
                            dateEnd = toDate
                            self?.dateLabel.text = dateBegin?.formatDateToStringToYear()
                        }
                        
                        self?.viewModel.dateBegin = dateBegin
                        self?.viewModel.dateEnd = dateEnd
                        self?.depositDateType = dateType
                    }
                }
                
                dest.dateType = self.depositDateType
            }
        }
        
        if segue.identifier == DepositRecordDetailViewController.segueIdentifier {
            if let dest = segue.destination as? DepositRecordDetailViewController {
                dest.detailRecord = sender as? DepositRecord
            }
        }
    }
    
    @objc func toDate(sender : UITapGestureRecognizer) {
        performSegue(withIdentifier: DateViewController.segueIdentifier, sender: nil)
    }
}

extension DepositRecordViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clear
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.whiteFull
        header.textLabel?.font = UIFont(name: "PingFangSC-Medium", size: 16.0)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
       return 32
    }
}

