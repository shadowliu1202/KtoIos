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
    
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var isLoading = false
    fileprivate var activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    fileprivate var curentFilter: [FilterItem]?
    fileprivate var depositDateType: DepositDateType = .week
    
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
        
        viewModel.elements.map { (data) -> [SectionModel<String, DepositRecord>]  in
            var sectionModels: [SectionModel<String, DepositRecord>] = []
            data.forEach {
                let today = Date().convertdateToUTC().formatDateToStringToDay()
                let sectionTitle = $0.0 == today ? Localize.string("common_today") : $0.0
                sectionModels.append(SectionModel(model: sectionTitle, items: $0.1))
            }
            
            return sectionModels
        }.asObservable().bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in () }
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx_reachedBottom
            .map{ _ in ()}
            .bind(to: self.viewModel.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        viewModel.loading.asObservable()
            .bind(to: isLoading(for: self.view))
            .disposed(by: disposeBag)
                
        self.filterBtn.rx.touchUpInside.subscribe(onNext: { [unowned self] in
            self.goToFilterVC()
        }).disposed(by: disposeBag)
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
    private func goToFilterVC() {
        let storyboard = UIStoryboard(name: "DepositFilter", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FilterConditionViewController") as! FilterConditionViewController
        let presenter = DepositPresenter()
        vc.presenter = presenter
        if let filter = curentFilter {
            presenter.setConditions(filter)
        }
        vc.conditionCallbck = { [weak self] (items) in
            self?.filterBtn.setTitle(items)
            self?.curentFilter = items
            let status: [TransactionStatus] = presenter.getConditionStatus(items)
            self?.viewModel.status = status
        }
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DateViewController.segueIdentifier {
            if let dest = segue.destination as? DateViewController {
                dest.conditionCallbck = {[weak self] (beginDate, endDate) in
                    self?.viewModel.dateBegin = beginDate
                    self?.viewModel.dateEnd = endDate
                    DispatchQueue.main.async {
                        let diffDays = beginDate.betweenTwoDay(sencondDate: endDate)
                        if beginDate == endDate {
                            self?.dateLabel.text = beginDate.formatDateToStringToDay()
                            self?.depositDateType = .day(beginDate.formatDateToStringToDay())
                        } else if diffDays == 6 {
                            self?.dateLabel.text = Localize.string("common_last7day")
                            self?.depositDateType = .week
                        } else {
                            self?.dateLabel.text = "\(beginDate.getYear())/\(beginDate.getMonth())"
                            self?.depositDateType = .month(beginDate.formatDateToStringToDay())
                        }
                    }
                }
                
                dest.depositDateType = self.depositDateType
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

