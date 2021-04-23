import UIKit
import RxSwift
import share_bu


class CasinoBetSummaryByDateViewController: UIViewController {
    static let segueIdentifier = "toCasinoBetSummaryByDate"
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    private var viewModel = DI.resolve(CasinoViewModel.self)!
    private var disposeBag = DisposeBag()
    private var sections: [Section] = []
    
    var selectDate: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = selectDate?.replacingOccurrences(of: "-", with: "/")
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        getBetSummaryByDate()
    }
    
    deinit {
        print("CasinoBetSummaryByDateViewController deinit")
    }
    
    private func getBetSummaryByDate() {
        viewModel.getBetSummaryByDate(localDate: selectDate!).subscribe {[weak self] (periodOfRecords) in
            self?.getBetRecords(periodOfRecords: periodOfRecords)
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    private func getBetRecords(periodOfRecords: [PeriodOfRecord]) {
        viewModel.getBetRecords(periodOfRecords: periodOfRecords).subscribe {[weak self] (dic) in
            for (p, betRecords) in dic {
                let dateTime = "(" + String(format: "%02d:%02d ~ %02d:%02d", p.startDate.hour, p.startDate.minute, p.endDate.hour, p.endDate.minute) + ")"
                self?.sections.append(Section(sectionClass: p.lobbyName, name: betRecords.map{ $0.gameName }, betId: betRecords.map{ $0.betId }, totalAmount: betRecords.map{ $0.stakes.amount }, winAmount: betRecords.map{ $0.winLoss.amount }, expanded: false, sectionDate: dateTime, betStatus: betRecords.map{ $0.getBetStatus() }, hasDetail: betRecords.map{ $0.hasDetails }, wagerId: betRecords.map{ $0.wagerId }, gameId: []))
            }
            
            self?.sections.sort(by: { (s1, s2) -> Bool in
                return s1.sectionDate! > s2.sectionDate!
            })
            
            self?.tableView.reloadData()
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == CasinoDetailViewController.segueIdentifier {
            if let dest = segue.destination as? CasinoDetailViewController {
                dest.wagerId = sender as? String
            }
        }
    }
}

extension CasinoBetSummaryByDateViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].name.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! BetRecordTableViewCell
        cell.setup(name: sections[indexPath.section].name[indexPath.row],
                   betId: sections[indexPath.section].betId[indexPath.row],
                   totalAmount: sections[indexPath.section].totalAmount[indexPath.row],
                   winAmount: sections[indexPath.section].winAmount[indexPath.row],
                   betStatus: sections[indexPath.section].betStatus[indexPath.row],
                   hasDetail: sections[indexPath.section].hasDetail[indexPath.row])
        if sections[indexPath.section].hasDetail[indexPath.row] == false {
            cell.selectionStyle = .none
        } else {
            cell.selectionStyle = .default
        }
        
        if (sections.count - 1) == indexPath.section && (sections.last!.betId.count - 1) == indexPath.row {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section].hasDetail[indexPath.row] {
            performSegue(withIdentifier: CasinoDetailViewController.segueIdentifier, sender: sections[indexPath.section].wagerId[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 58
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (sections[indexPath.section].expanded) {
            return 118
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ExpandableHeaderView()
        header.customInit(title: sections[section].sectionClass, section: section, delegate: self, date: sections[section].sectionDate)
        return header
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! ExpandableHeaderView
        view.addSubview(header.imageView)
        view.addSubview(header.dateTimeLabel)
        header.imageView.image = UIImage(named: "arrow-drop-down")
        header.imageView.translatesAutoresizingMaskIntoConstraints = false
        header.imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        header.imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        header.textLabel?.sizeToFit()
        header.dateTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        header.dateTimeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        header.dateTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: header.textLabel!.frame.width + 39).isActive = true
        header.dateTimeLabel.textColor = UIColor.textSecondaryScorpionGray
        header.dateTimeLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)
    }
}


extension CasinoBetSummaryByDateViewController: ExpandableHeaderViewDelegate {
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
