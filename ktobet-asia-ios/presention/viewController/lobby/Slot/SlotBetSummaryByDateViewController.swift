import UIKit
import RxSwift
import share_bu
import SDWebImage

class SlotBetSummaryByDateViewController: UIViewController {
    static let segueIdentifier = "toSlotBetSummaryByDate"
    var selectDate: String? = ""
    var viewModel = DI.resolve(SlotBetViewModel.self)!
    private var disposeBag = DisposeBag()
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }

    private func initUI() {
        titleLabel.text = selectDate?.replacingOccurrences(of: "-", with: "/")
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        gameImgView.sd_cancelCurrentImageLoad()
        gameImgView.image = nil
    }
    
    func configure(_ item: SlotGroupedRecord) -> Self {
        gameImgView.sd_setImage(with: URL(string: item.slotThumbnail.url()), completed: nil)
        gameLabel.text = item.gameName
        betCountLabel.text = Localize.string("product_count_bet_record", "\(item.recordCount)")
        let status = item.winloss.isPositive() ? Localize.string("common_win") : Localize.string("common_lose")
        betAmountLabel.text = Localize.string("product_total_bet", item.stakes.amount.currencyFormatWithoutSymbol(precision: 2)) + "  " + status + " \(abs(item.winloss.amount).currencyFormatWithoutSymbol(precision: 2))"
        
        return self
    }
}
