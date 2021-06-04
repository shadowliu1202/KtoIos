import UIKit
import RxSwift
import SharedBu

class SlotBetDetailViewController: UIViewController {
    static let segueIdentifier = "toSlotBetDetail"
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel = DI.resolve(SlotBetViewModel.self)!
    var recordData: SlotGroupedRecord?
    var records: [SlotBetRecord] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let disposeBag = DisposeBag()
    
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
        titleLabel.text = recordData?.gameName
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView?.addBorderBottom(size: 0.5, color: UIColor.dividerCapeCodGray2)
        tableView.tableFooterView?.addBorderTop(size: 0.5, color: UIColor.dividerCapeCodGray2)
    }
    
    private func dataBinding() {
        self.fetchNextBetRecords(0)
        viewModel.betRecordDetails.catchError({ [weak self] (error) in
            self?.handleUnknownError(error)
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
        return tableView.dequeueReusableCell(withIdentifier: "SlotBetDetailCell", cellType: SlotBetDetailCell.self).configure(self.records[indexPath.row])
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
        let status = item.winLoss.isPositive() ? Localize.string("common_win") : Localize.string("common_lose")
        self.amountLabel.text = Localize.string("product_total_bet", item.stakes.amount.currencyFormatWithoutSymbol(precision: 2)) + "  " + status + " \(abs(item.winLoss.amount).currencyFormatWithoutSymbol(precision: 2))"
        
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
        
        
        if let winLoss = item.winLoss, winLoss.amount != 0 {
            let status = winLoss.amount >= 0 ? Localize.string("common_win") : Localize.string("common_lose")
            amountLabel.text = Localize.string("product_total_bet", item.betAmount.amount.currencyFormatWithoutSymbol(precision: 2)) + "  " + status + " \(abs(winLoss.amount).currencyFormatWithoutSymbol(precision: 2))"
        } else {
            amountLabel.text = Localize.string("product_total_bet", item.betAmount.amount.currencyFormatWithoutSymbol(precision: 2))
        }
    }
}
