import UIKit
import RxSwift
import SharedBu
import SDWebImage

class SlotBetSummaryByDateViewController: UIViewController {
    static let segueIdentifier = "toSlotBetSummaryByDate"
    var selectDate: String? = ""
    var viewModel = DI.resolve(SlotBetViewModel.self)!
    private var disposeBag = DisposeBag()
    
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self, title: selectDate?.replacingOccurrences(of: "-", with: "/"))
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }

    private func initUI() {
        tableView.tableHeaderView?.addBorderBottom(size: 0.5, color: UIColor.dividerCapeCodGray2)
        tableView.tableFooterView?.addBorderTop(size: 0.5, color: UIColor.dividerCapeCodGray2)
    }
    
    private func dataBinding() {
        guard let selectDate = selectDate else { return }
        viewModel.betSummaryByDate(localDate: selectDate).asObservable().bind(to: tableView.rx.items){ tableView, row, item in
            return tableView.dequeueReusableCell(withIdentifier: "SlotBetSummaryByDateCell", cellType: SlotBetSummaryByDateCell.self).configure(item)
        }.disposed(by: disposeBag)
        tableView.rx.modelSelected(SlotGroupedRecord.self).bind{ [unowned self] (data) in
            self.performSegue(withIdentifier: SlotBetDetailViewController.segueIdentifier, sender: data)
        }.disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SlotBetDetailViewController.segueIdentifier {
            if let dest = segue.destination as? SlotBetDetailViewController {
                dest.recordData = sender as? SlotGroupedRecord
            }
        }
    }
}

class SlotBetSummaryByDateCell: UITableViewCell {
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var betCountLabel: UILabel!
    @IBOutlet weak var betAmountLabel: UILabel!
    @IBOutlet weak var gameImgView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        gameImgView.sd_cancelCurrentImageLoad()
        gameImgView.image = nil
    }
    
    func configure(_ item: SlotGroupedRecord) -> Self {
        gameImgView.sd_setImage(with: URL(string: item.slotThumbnail.url()), completed: nil)
        gameLabel.text = item.gameName
        betCountLabel.text = Localize.string("product_count_bet_record", "\(item.recordCount)")
        betAmountLabel.text = CashAmount.productTotalBet(betAmount: item.stakes, winLoss: item.winloss)
        
        return self
    }
    
    func configure(_ item: NumberGameSummary.Game) {
        gameImgView.sd_setImage(with: URL(string: item.thumbnail.url()), completed: nil)
        gameLabel.text = item.gameName
        betCountLabel.text = Localize.string("product_count_bet_record", "\(item.totalRecords)")
        betAmountLabel.text = CashAmount.productTotalBet(betAmount: item.betAmount, winLoss: item.winLoss)
    }
}
