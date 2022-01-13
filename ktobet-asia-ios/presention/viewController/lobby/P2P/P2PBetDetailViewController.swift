import UIKit
import RxSwift
import SharedBu

class P2PBetDetailViewController: APPViewController {
    static let segueIdentifier = "toP2PBetDetail"
    var recordData: GameGroupedRecord?
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel = DI.resolve(P2PBetViewModel.self)!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: recordData?.gameName)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        tableView.setHeaderFooterDivider(dividerInset: UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24))
    }
    
    private func dataBinding() {
        guard let recordData = recordData else { return }
        viewModel.getBetDetail(startDate: recordData.startDate.description(), endDate: recordData.endDate.description(), gameId: recordData.gameId).asObservable()
            .catchError({ [weak self] (error) -> Observable<[P2PGameBetRecord]> in
                self?.handleUnknownError(error)
                return Observable.empty()
            }).bind(to: tableView.rx.items) { tableView, row, item in
                return tableView.dequeueReusableCell(withIdentifier: "P2PBetDetailCell", cellType: BetDetailCell.self).configure(item)
        }.disposed(by: disposeBag)
    }
}

class BetDetailCell: UITableViewCell {
    @IBOutlet weak var betIdLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    func configure(_ item: P2PGameBetRecord) -> Self {
        self.selectionStyle = .none
        self.betIdLabel.text = item.groupId
        let date = item.betTime.convertToDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let dateString: String = dateFormatter.string(from: date)
        self.timeLabel.text = "\(dateString)".uppercased()
        let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
        self.amountLabel.text = Localize.string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winLoss.formatString())"
        
        return self
    }
    
    func configure(_ item: ArcadeGameBetRecord) {
        self.selectionStyle = .none
        self.betIdLabel.text = item.betId
        let dateString: String = item.betTime.toTimeString()
        self.timeLabel.text = "\(dateString)".uppercased()
        let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
        self.amountLabel.text = Localize.string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winLoss.formatString())"
    }
}
