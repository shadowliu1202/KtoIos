import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import SharedBu
import SwiftUI

class DepositRecordViewController: LobbyViewController {
    static let segueIdentifier = "toAllRecordSegue"
    
    @IBOutlet private weak var dateView: KTODateView!
    @IBOutlet private weak var filterBtn: FilterButton!
    @IBOutlet private weak var depositRecordTitle: UILabel!
    @IBOutlet private weak var depositTotalTitle: UILabel!
    @IBOutlet private weak var depositTotalAmount: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyView: UIView!
    
    private lazy var filterPersenter = DepositPresenter()
    private var depositLogViewModel = Injectable.resolve(DepositLogViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var isLoading = false
    fileprivate var activityIndicator = UIActivityIndicatorView(style: .large)
    fileprivate var curentFilter: [FilterItem]?
    fileprivate var depositDateType: DateType = .week()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
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
        tableView.delegate = self
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        dateView.callBackCondition = {[weak self] (dateBegin, dateEnd, dateType) in
            self?.depositLogViewModel.dateBegin = dateBegin
            self?.depositLogViewModel.dateEnd = dateEnd
            self?.depositDateType = dateType
        }
        
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let bankFilterVC = storyboard.instantiateViewController(withIdentifier: "BankFilterConditionViewController") as! BankFilterConditionViewController
        filterBtn.set(filterPersenter)
            .set(curentFilter)
            .setGotoFilterVC(vc: bankFilterVC)
            .set { [weak self] (items) in
                guard let `self` = self else { return }
                self.curentFilter = items as? [TransactionItem]
                self.filterBtn.set(self.curentFilter)
                let status: [PaymentLogDTO.LogStatus] = self.filterPersenter.getConditionStatus(items as! [DepositTransactionItem])
                self.depositLogViewModel.status = status
        }
    }
    
    fileprivate func getDepositRecord() {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, PaymentLogDTO.Log>>(
            configureCell: { (_, tv, indexPath, element) in
                let cell = tv.dequeueReusableCell(withIdentifier: String(describing: DepositRecordTableViewCell.self)) as! DepositRecordTableViewCell
                cell.setup(element, displayFormat: .time)
                return cell
            },
            titleForHeaderInSection: { dataSource, sectionIndex in
                return dataSource[sectionIndex].model
            }
        )
        depositLogViewModel.pagination.elements.map { (records: [PaymentLogDTO.GroupLog]) -> [SectionModel<String, PaymentLogDTO.Log>] in
            var sectionModels: [SectionModel<String, PaymentLogDTO.Log>] = []
            let sortedData = records.sorted(by: { $0.groupDate.toDateTimeString() > $1.groupDate.toDateTimeString() })
            sortedData.forEach {
                let today = Date().convertdateToUTC().toDateString()
                let sectionTitle = $0.groupDate.toDateString() == today ? Localize.string("common_today") : $0.groupDate.toDateString()
                sectionModels.append(SectionModel(model: sectionTitle, items: $0.logs))
            }
            return sectionModels
        }.asObservable().catchError({ [weak self] (error) -> Observable<[SectionModel<String, PaymentLogDTO.Log>]> in
            self?.handleErrors(error)
            return Observable.just([])
        }).bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)

        depositLogViewModel.pagination.elements.map{ $0.count != 0 }.debug().bind(to: emptyView.rx.isHidden).disposed(by: disposeBag)

        rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in () }
            .bind(to: depositLogViewModel.pagination.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx.reachedBottom
            .map{ _ in ()}
            .bind(to: self.depositLogViewModel.pagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        depositLogViewModel.pagination.loading.asObservable()
            .bind(to: isLoading(for: self.view))
            .disposed(by: disposeBag)
                
    }
    
    fileprivate func recordDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(PaymentLogDTO.Log.self)).bind { [weak self] (indexPath, data) in
            let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "DepositRecordContainer") as! DepositRecordContainer
            vc.displayId = data.displayId
            vc.paymentCurrencyType = data.currencyType
            self?.navigationController?.pushViewController(vc, animated: true)
            self?.tableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func getDepositSummary() {
        depositLogViewModel.getCashLogSummary().subscribe { (currencyUnit) in
            self.depositTotalAmount.text = currencyUnit.formatString()
        } onError: { (error) in
            self.handleErrors(error)
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

