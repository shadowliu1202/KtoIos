import UIKit
import RxSwift
import RxDataSources
import SharedBu

class P2PSummaryViewController: UIViewController {
    @IBOutlet private weak var noDataView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    
    private var viewModel = DI.resolve(P2PBetViewModel.self)!
    private var disposeBag = DisposeBag()
    private var unfinishGameCount: Int32 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self, title: Localize.string("product_my_bet"))
        initUI()
        bindingSummaryData()
        summaryDataHandler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchBetSummary()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.setHeaderFooterDivider()
    }
    
    private func bindingSummaryData() {
        viewModel.betSummary
            .catchError({ [weak self] (error) -> Observable<MyBetSummary> in
                switch error {
                case KTOError.EmptyData:
                    self?.switchContent()
                    break
                default:
                    self?.handleUnknownError(error)
                }
                return Observable.empty()
            })
            .map {[weak self] (betSummary) -> [Record] in
                guard let self = self else { return [] }
                self.switchContent(betSummary)
                return betSummary.finishedGame
            }.bind(to: tableView.rx.items) { (tableView, row, element) in
                return tableView.dequeueReusableCell(withIdentifier: "MyBetSummaryTableViewCell", cellType: MyBetSummaryTableViewCell.self).config(element: element)
        }.disposed(by: disposeBag)
    }
    
    private func switchContent(_ summary: MyBetSummary? = nil) {
        if let items = summary, hasGameRecords(summary: items) {
            self.tableView.isHidden = false
            self.noDataView.isHidden = true
        } else {
            self.tableView.isHidden = true
            self.noDataView.isHidden = false
        }
    }
    
    private func summaryDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(Record.self)).bind {[weak self] (indexPath, data) in
            self?.performSegue(withIdentifier: P2PBetSummaryByDateViewController.segueIdentifier, sender: "\(data.createdDateTime)")
        }.disposed(by: disposeBag)
    }
    
    private func hasGameRecords(summary: MyBetSummary) -> Bool {
        return summary.finishedGame.count != 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == P2PBetSummaryByDateViewController.segueIdentifier {
            if let dest = segue.destination as? P2PBetSummaryByDateViewController {
                dest.selectDate = sender as? String
            }
        }
    }
}

extension P2PSummaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 && unfinishGameCount != 0 ? 57 : 81
    }
}

class SummaryAdapter: MyBetSummary {
    var beans: [DateSummary] = []
    init(_ beans: [DateSummary]) {
        super.init()
        self.beans = beans
        self.unfinishGameCount = 0
        self.finishedGame = beans.map({ (element) in
            return Record(count: Int(element.count), createdDateTime: element.createdDateTime.toDateFormatString(), totalStakes: element.totalStakes, totalWinLoss: element.totalWinLoss)
        })
    }
}
