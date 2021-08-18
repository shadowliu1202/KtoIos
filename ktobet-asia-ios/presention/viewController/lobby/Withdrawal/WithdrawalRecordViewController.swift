import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import SharedBu
import SwiftUI

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
    fileprivate var activityIndicator = UIActivityIndicatorView(style: .large)
    fileprivate var curentFilter: [FilterItem]?
    fileprivate var withdrawalDateType: DateType = .week()
    
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
            let sortedData = records.sorted(by: { $0.createDate.toDateTimeString() > $1.createDate.toDateTimeString() })
            let groupDic = Dictionary(grouping: sortedData, by: { String(format: "%02d/%02d/%02d", $0.groupDay.year, $0.groupDay.monthNumber, $0.groupDay.dayOfMonth) })
            let tupleData: [(String, [WithdrawalRecord])] = groupDic.dictionaryToTuple()
            tupleData.forEach{
                let today = Date().convertdateToUTC().toDateString()
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
            if data.transactionTransactionType == TransactionType.cryptowithdrawal {
                self.viewModel.getWithdrawalRecordDetail(transactionId: data.displayId, transactionTransactionType: data.transactionTransactionType).subscribe {(withdrawalDetail) in
                    let swiftUIView = WithdrawalCryptoDetailView(data: withdrawalDetail as? WithdrawalDetail.Crypto)
                    let hostingController = UIHostingController(rootView: swiftUIView)
                    hostingController.navigationItem.hidesBackButton = true
                    NavigationManagement.sharedInstance.pushViewController(vc: hostingController)
                } onError: {[weak self] (error) in
                    self?.handleUnknownError(error)
                }.disposed(by: self.disposeBag)
            } else {
                self.performSegue(withIdentifier: WithdrawalRecordDetailViewController.segueIdentifier, sender: data)
            }
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
        vc.conditionCallbck = {[weak self] (dateType) in
            DispatchQueue.main.async {
                let dateBegin: Date?
                let dateEnd: Date?
                switch dateType {
                case .day(let day):
                    self?.dateLabel.text = day.toMonthDayString()
                    dateBegin = day
                    dateEnd = day
                case .week(let fromDate, let toDate):
                    self?.dateLabel.text = Localize.string("common_last7day")
                    dateBegin = fromDate
                    dateEnd = toDate
                case .month(let fromDate, let toDate):
                    dateBegin = fromDate
                    dateEnd = toDate
                    self?.dateLabel.text = dateBegin?.toYearMonthString()
                }
                
                self?.viewModel.dateBegin = dateBegin
                self?.viewModel.dateEnd = dateEnd
                self?.withdrawalDateType = dateType
            }
        }
        
        vc.dateType = self.withdrawalDateType
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
