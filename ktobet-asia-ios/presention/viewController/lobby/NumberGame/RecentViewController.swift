import UIKit
import RxSwift
import RxCocoa
import SharedBu

class RecentViewController: UIViewController {
    @IBOutlet private weak var noDataView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    
    var viewModel: NumberGameRecordViewModel!
    private var details: [NumberGameBetDetail]?
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        tableView.tableFooterView?.addBorderTop(size: 0.5, color: UIColor.dividerCapeCodGray2)
    }
    
    private func dataBinding() {
        let shareRecent = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return self.viewModel.recent
        }).share()
        shareRecent.catchError({ [weak self] (error) -> Observable<[NumberGameSummary.RecentlyBet]> in
            self?.handleErrors(error)
            return Observable.just([])
        }).do ( onNext:{[weak self] (records) in
            self?.switchContent(records.count)
        }).bind(to: tableView.rx.items) { tableView, row, item in
            return tableView.dequeueReusableCell(withIdentifier: "NumbergameRecentCell", cellType: NumbergameRecentCell.self).configure(item)
        }.disposed(by: disposeBag)
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(NumberGameSummary.RecentlyBet.self)).bind{ [unowned self] (indexPath, data) in
            self.performSegue(withIdentifier: NumberGameMyBetDetailViewController.segueIdentifier, sender: indexPath.row)
        }.disposed(by: disposeBag)
        shareRecent.flatMap({ [unowned self] (array : [NumberGameSummary.RecentlyBet]) -> Observable<[NumberGameBetDetail]> in
            let wagerIds: [String] = array.map{ $0.wagerId }
            return self.viewModel.getRecentGamesDetail(wagerIds: wagerIds).asObservable()
        }).subscribe(onNext: { [weak self] (details: [NumberGameBetDetail]) in
            self?.details = details
        }).disposed(by: disposeBag)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NumberGameMyBetDetailViewController.segueIdentifier {
            if let dest = segue.destination as? NumberGameMyBetDetailViewController {
                dest.details = self.details
                if let row = sender as? Int {
                    dest.selectedIndex = row
                }
            }
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

class NumbergameRecentCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var matchMethodLabel: UILabel!
    @IBOutlet weak var betAmountLabel: UILabel!
    @IBOutlet weak var arrow: UIImageView!
    
    func configure(_ item: NumberGameSummary.RecentlyBet) -> Self {
        titleLabel.text = item.betTypeName.isEmpty ? item.selection : "\(item.betTypeName) :\(item.selection)"
        productNameLabel.text = item.gameName
        matchMethodLabel.text = item.matchMethod
        let status = item.status
        if status is NumberGameBetDetail.BetStatusSettledWinLose {
            let amount: CashAmount = (status as! NumberGameBetDetail.BetStatusSettledWinLose).winLoss
            betAmountLabel.text = CashAmount.productTotalBet(betAmount: item.stakes, winLoss: amount)
        } else {
            betAmountLabel.text = Localize.string("product_total_bet", item.stakes.displayAmount) + " \(status.LocalizeString)"
        }
        arrow.isHidden = !item.hasDetail
        return self
    }
    
    private func parseWinLose(winLoss: CashAmount) -> String {
        return winLoss.isPositive() ? Localize.string("common_win") : Localize.string("common_lose")
    }
    
}
