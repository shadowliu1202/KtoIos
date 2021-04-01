import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import share_bu

class WithdrawalRecordViewController: UIViewController {
    static let segueIdentifier = "toAllRecordSegue"
    
    @IBOutlet private weak var dateView: UIView!
    @IBOutlet private weak var filterBtn: FilterButton!
    @IBOutlet private weak var withdrawalRecordTitle: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    private lazy var filterPersenter = WithdrawalPresenter()
    fileprivate var viewModel = DI.resolve(WithdrawalViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var isLoading = false
    fileprivate var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    fileprivate var curentFilter: [TransactionItem]?
    fileprivate var withdrawalDateType: DateType = .week
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        getWithdrawalRecord()
        recordDataHandler()
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        withdrawalRecordTitle.text = Localize.string("withdrawal_log")
        dateView.layer.cornerRadius = 8
        dateView.layer.masksToBounds = true
        dateView.layer.borderWidth = 1
        dateView.layer.borderColor = UIColor.textPrimaryDustyGray.cgColor
        tableView.delegate = self
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        let tap = UITapGestureRecognizer.init()
        self.dateView.addGestureRecognizer(tap)
        tap.rx.event.subscribe {[weak self] (gesture) in
            self?.goToDateVC()
        }.disposed(by: self.disposeBag)
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
    
    fileprivate func getWithdrawalRecord() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, WithdrawalRecord>>(
            configureCell: { (_, tv, indexPath, element) in
                let cell = tv.dequeueReusableCell(withIdentifier: String(describing: WithdrawRecordTableViewCell.self)) as! WithdrawRecordTableViewCell
                cell.setUp(data: element)
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
                
        viewModel.pagination.elements.map { (records) -> [SectionModel<String, WithdrawalRecord>] in
            var sectionModels: [SectionModel<String, WithdrawalRecord>] = []
            let sortedData = records.sorted(by: { $0.createDate.formatDateToStringToSecond() > $1.createDate.formatDateToStringToSecond() })
            let groupDic = Dictionary(grouping: sortedData, by: { String(format: "%02d/%02d/%02d", $0.groupDay.year, $0.groupDay.monthNumber, $0.groupDay.dayOfMonth) })
            let tupleData: [(String, [WithdrawalRecord])] = groupDic.dictionaryToTuple()
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
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(WithdrawalRecord.self)).bind {(indexPath, data) in
            self.performSegue(withIdentifier: WithdrawalRecordDetailViewController.segueIdentifier, sender: data)
            self.tableView.deselectRow(at: indexPath, animated: true)
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
    fileprivate func goToDateVC() {
        let storyboard = UIStoryboard(name: "Deposit", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DateConditionViewController") as! DateViewController
        vc.conditionCallbck = {[weak self] (beginDate, endDate) in
            self?.viewModel.dateBegin = beginDate
            self?.viewModel.dateEnd = endDate
            DispatchQueue.main.async {
                let diffDays = beginDate.betweenTwoDay(sencondDate: endDate)
                if beginDate == endDate {
                    self?.dateLabel.text = beginDate.formatDateToStringToDay()
                    self?.withdrawalDateType = .day(beginDate.formatDateToStringToDay())
                } else if diffDays == 6 {
                    self?.dateLabel.text = Localize.string("common_last7day")
                    self?.withdrawalDateType = .week
                } else {
                    self?.dateLabel.text = "\(beginDate.getYear())/\(beginDate.getMonth())"
                    self?.withdrawalDateType = .month(beginDate.formatDateToStringToDay())
                }
            }
        }
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalRecordDetailViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalRecordDetailViewController {
                dest.detailRecord = sender as? WithdrawalRecord
            }
        }
    }
}


extension WithdrawalRecordViewController: UITableViewDelegate {
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
