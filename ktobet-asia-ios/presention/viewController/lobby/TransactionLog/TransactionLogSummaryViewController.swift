import UIKit
import RxSwift
import SharedBu

class TransactionLogSummaryViewController: LobbyViewController {
    static let segueIdentifier = "toTransactionLogSummary"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var beginDateLabel: UILabel!
    @IBOutlet weak var beginAmountLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endAmountLabel: UILabel!
    
    let disposeBag = DisposeBag()
    var viewModel: TransactionLogViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        tableView.addTopBorder()
        tableView.addBottomBorder()
        viewModel.getCashLogSummary()
            .do(onSuccess: {[weak self] summary in
                guard let self = self else { return }
                self.beginDateLabel.text = String(format: Localize.string("balancelog_summary_start_date"), self.viewModel.from!.toDateString())
                self.beginAmountLabel.text = String(format: Localize.string("balancelog_summary_start_amount"), summary.previousBalance)
                self.endDateLabel.text = Date().convertdateToUTC() <= self.viewModel.to!.convertdateToUTC() ?
                String(format: Localize.string("balancelog_summary_end_date"), Date().toDateString()) :
                String(format: Localize.string("balancelog_summary_end_date"), self.viewModel.to!.toDateString())
                self.endAmountLabel.text = Date().convertdateToUTC() <= self.viewModel.to!.convertdateToUTC() ? Localize.string("balancelog_summary_end_date_is_today") : String(format: Localize.string("balancelog_summary_end_amount"), summary.afterBalance)
            })
            .map({summary -> [LogSummaryModel] in
                var logSummary: [LogSummaryModel] = []
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_deposit"), amount: summary.deposit))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_withdrawal"), amount: summary.withdrawal))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_sportsbook"), amount: summary.sportsBook))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_slot"), amount: summary.slot))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_casino"), amount: summary.casino))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_keno"), amount: summary.numberGame))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_p2p"), amount: summary.p2pAmount))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_arcade"), amount: summary.arcadeAmount))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_adjustment"), amount: summary.adjustmentAmount))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_bonus"), amount: summary.bonusAmount))
                logSummary.append(LogSummaryModel(typeName: Localize.string("common_total_amount"), amount: summary.totalSummary))
                
                return logSummary
            }).asObservable()
            .catchError({ [weak self] in
                self?.handleErrors($0)
                return Observable.just([])
            }).bind(to: tableView.rx.items) {tableView, row, element in
                let cell = tableView.dequeueReusableCell(withIdentifier: TransactionLogSummaryTableViewCell.identifier) as! TransactionLogSummaryTableViewCell
                cell.removeBorder()
                cell.typeLabel.text = element.typeName
                cell.amountLabel.text = element.amount.formatString(sign: .signed_)
                cell.amountLabel.textColor = element.amount.isPositive ? .textSuccessedGreen : .textPrimaryDustyGray
                cell.addBorder()
                return cell
            }.disposed(by: disposeBag)
    }
}

struct LogSummaryModel {
    var typeName: String = ""
    var amount: AccountCurrency
}
