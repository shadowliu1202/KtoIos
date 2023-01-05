import UIKit
import RxSwift
import SharedBu

class SlotBetDetailViewController: LobbyViewController {
    static let segueIdentifier = "toSlotBetDetail"
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel = Injectable.resolve(SlotBetViewModel.self)!
    var recordData: SlotGroupedRecord?
    var records: [SlotBetRecord] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
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
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setHeaderFooterDivider()
    }
    
    private func dataBinding() {
        self.fetchNextBetRecords(0)
        viewModel.betRecordDetails.catchError({ [weak self] (error) in
            self?.handleErrors(error)
            return Observable.just(self?.records ?? [])
        }).subscribe(onNext: { [weak self] (data) in
            self?.records = data
        }).disposed(by: disposeBag)
    }
    
    func fetchNextBetRecords(_ lastIndex: Int) {
        guard let recordData = recordData else { return }
        viewModel.fetchNextBetRecords(recordData: recordData, lastIndex)
    }
    
}

extension SlotBetDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SlotBetDetailCell", cellType: SlotBetDetailCell.self).configure(self.records[indexPath.row])
        cell.removeBorder()
        if indexPath.row != 0 {
            cell.addBorder(rightConstant: 24, leftConstant: 24)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isLoadingIndexPath(tableView, indexPath) && viewModel.hasNextRecord(indexPath.row) {
            self.fetchNextBetRecords(indexPath.row)
        }
    }
    
    private func isLoadingIndexPath(_ tableView: UITableView, _ indexPath: IndexPath) -> Bool {
        let lastSectionIndex = tableView.numberOfSections - 1
        let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
        return indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex
    }
}

class SlotBetDetailCell: UITableViewCell {
    @IBOutlet weak var betIdLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    func configure(_ item: SlotBetRecord) -> Self {
        self.selectionStyle = .none
        self.betIdLabel.text = item.betId
        let date = item.betTime.convertToDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let dateString: String = dateFormatter.string(from: date)
        self.timeLabel.text = "\(dateString)".uppercased()
        let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
        self.amountLabel.text = Localize.string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winLoss.formatString(.none))"
        
        return self
    }
    
    func configure(_ item: NumberGameSummary.Bet) {
        self.selectionStyle = .none
        self.betIdLabel.text = item.displayId
        let date = item.time.convertToDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let dateString: String = dateFormatter.string(from: date)
        self.timeLabel.text = "\(dateString)".uppercased()
        self.iconImageView.isHidden = !item.hasDetail
        self.isUserInteractionEnabled = item.hasDetail
        
        if let winLoss = item.winLoss {
            let status = winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
            amountLabel.text = Localize.string("product_total_bet", item.betAmount.description()) + "  " + status + " \(winLoss.formatString(.none))"
        } else {
            amountLabel.text = Localize.string("product_total_bet", item.betAmount.description())
        }
    }
}
