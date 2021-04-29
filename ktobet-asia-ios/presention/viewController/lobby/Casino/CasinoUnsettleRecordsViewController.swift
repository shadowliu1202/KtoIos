import UIKit
import RxSwift
import share_bu


class CasinoUnsettleRecordsViewController: UIViewController {
    static let segueIdentifier = "toCasinoUnsettleRecords"
    @IBOutlet private weak var tableView: UITableView!
    
    private var viewModel = DI.resolve(CasinoViewModel.self)!
    private var disposeBag = DisposeBag()
    private var sections: [Section] = []
    
    private var test: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        getUnsettledBetSummary()
    }
    
    deinit {
        print("CasinoUnsettleRecordsViewController deinit")
    }
    
    private func getUnsettledBetSummary() {
        viewModel.getUnsettledBetSummary().subscribe {[weak self] (UnsettledBetSummaries) in
                self?.getUnsettledRecords()
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    private func getUnsettledRecords() {
        viewModel.getUnsettledRecords().subscribe(onNext: {[weak self] (dic) in
            for (date, records) in dic {
                self?.sections.append(Section(sectionClass: date, name: records.map{ $0.gameName }, betId: records.map{ $0.betId }, totalAmount: records.map{ $0.stakes.amount }, expanded: false, gameId: records.map{ $0.gameId }))
            }
            
            self?.sections.sort(by: { (s1, s2) -> Bool in
                return s1.sectionClass! > s2.sectionClass!
            })
            
            self?.tableView.reloadData()
        }, onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
    }
}


extension CasinoUnsettleRecordsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].name.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! BetRecordTableViewCell
        cell.setupUnSettleGame(sections[indexPath.section].name[indexPath.row],
                   betId: sections[indexPath.section].betId[indexPath.row],
                   totalAmount: sections[indexPath.section].totalAmount[indexPath.row])
        if (sections.count - 1) == indexPath.section && (sections.last!.betId.count - 1) == indexPath.row {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Casino", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "GameWebViewViewController") as! GameWebViewViewController
        vc.gameId = sections[indexPath.section].gameId[indexPath.row]
        vc.gameProduct = "casino"
        present(vc, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 58
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (sections[indexPath.section].expanded) {
            return 97
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ExpandableHeaderView()
        header.customInit(title: sections[section].sectionClass, section: section, delegate: self)
        return header
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! ExpandableHeaderView
        header.imageView.frame = CGRect(x: view.frame.width - 44, y: view.frame.height / 2 - 10, width: 20, height: 20)
        header.imageView.image = UIImage(named: "arrow-drop-down")
        view.addSubview(header.imageView)
    }
}

extension CasinoUnsettleRecordsViewController: ExpandableHeaderViewDelegate {
    func toggleSection(header: ExpandableHeaderView, section: Int) {
        sections[section].expanded = !(sections[section].expanded)
        header.imageView.image = sections[section].expanded ? UIImage(named: "arrow-drop-up") : UIImage(named: "arrow-drop-down")
        tableView.beginUpdates()
        for i in 0 ..< sections[section].name.count {
            tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .automatic)
        }
        
        tableView.endUpdates()
    }
    
}


struct Section {
    var gameId: [Int32] = []
    var sectionClass: String!
    var sectionDate: String?
    var name: [String] = []
    var betId: [String] = []
    var totalAmount: [Double] = []
    var winAmount: [Double] = []
    var expanded: Bool = false
    var betStatus: [BetStatus] = []
    var hasDetail: [Bool] = []
    var wagerId: [String] = []
    var periodOfRecord: PeriodOfRecord!
    
    init() { }
    
    init(periodOfRecord: PeriodOfRecord) {
        self.periodOfRecord = periodOfRecord
        let dateTime = "(" + String(format: "%02d:%02d ~ %02d:%02d", self.periodOfRecord.startDate.hour, self.periodOfRecord.startDate.minute, self.periodOfRecord.endDate.hour, self.periodOfRecord.endDate.minute) + ")"
        self.sectionDate = dateTime
        self.sectionClass = self.periodOfRecord.lobbyName
    }
    
    init(sectionClass: String, name: [String] = [], betId: [String] = [], totalAmount: [Double] = [], winAmount: [Double] = [], expanded: Bool, sectionDate: String? = nil, betStatus: [BetStatus] = [], hasDetail: [Bool] = [], wagerId: [String] = [], gameId: [Int32] = []) {
        self.sectionClass = sectionClass
        self.name = name
        self.betId = betId
        self.totalAmount = totalAmount
        self.winAmount = winAmount
        self.betStatus = betStatus
        self.expanded = expanded
        self.sectionDate = sectionDate ?? ""
        self.hasDetail = hasDetail
        self.wagerId = wagerId
        self.gameId = gameId
    }
}
