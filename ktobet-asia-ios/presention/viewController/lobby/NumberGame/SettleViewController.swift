import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SharedBu

class SettleViewController: UIViewController {
    @IBOutlet private weak var noDataView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    
    var viewModel: NumberGameRecordViewModel!
    private var disposeBag = DisposeBag()
    private var dataSource = BehaviorRelay(value: [NumberGameSummary.Date]())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        summaryDataHandler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bindingSummaryData()
    }
    
    private func initUI() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.setHeaderFooterDivider(headerHeight: 86, headerColor: UIColor.clear, headerDividerColor: UIColor.clear)
        dataSource.do ( onNext:{[weak self] (records) in
            self?.switchContent(records.count)
        })
        .bind(to: tableView.rx.items) {[weak self] (tableView, row, element) in
            guard let self = self else { return  UITableViewCell()}
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "CasinoSummaryTableViewCell", cellType: CasinoSummaryTableViewCell.self)
            cell.setup(element: element)
            return cell
        }.disposed(by: disposeBag)
    }
    
    private func bindingSummaryData() {
        viewModel.settled.subscribe {[weak self] (data) in
            self?.dataSource.accept(data)
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    private func switchContent(_ count: Int) {
        if count != 0 {
            self.tableView.isHidden = false
            self.noDataView.isHidden = true
        } else {
            self.tableView.isHidden = true
            self.noDataView.isHidden = false
        }
    }
    
    private func summaryDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(NumberGameSummary.Date.self)).bind {[weak self] (indexPath, data) in
            guard let self = self else { return }
            let parameter = (data.betDate, NumberGameSummary.CompanionStatus.settled)
            self.performSegue(withIdentifier: NumberGameMyBetGameGroupedViewController.segueIdentifier, sender: parameter)
        }.disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NumberGameMyBetGameGroupedViewController.segueIdentifier {
            if let dest = segue.destination as? NumberGameMyBetGameGroupedViewController {
                let parameter = sender as! (betDate: Kotlinx_datetimeLocalDate, status: NumberGameSummary.CompanionStatus)
                dest.betDate = parameter.betDate
                dest.betStatus = parameter.status
            }
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
}

extension SettleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
}
