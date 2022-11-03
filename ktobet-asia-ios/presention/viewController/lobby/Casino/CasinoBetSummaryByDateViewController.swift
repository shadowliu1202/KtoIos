import UIKit
import RxSwift
import RxCocoa
import SharedBu


class CasinoBetSummaryByDateViewController: LobbyViewController {
    static let segueIdentifier = "toCasinoBetSummaryByDate"
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var viewModel = Injectable.resolve(CasinoViewModel.self)!
    private var disposeBag = DisposeBag()
    private var sections: [Section] = []
    
    var selectDate: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: selectDate?.replacingOccurrences(of: "-", with: "/"))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setHeaderFooterDivider(headerColor: UIColor.black_two)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        getBetSummaryByDate()
        viewModel.pagination.elements.subscribe(onNext: { (betRecords) in
            if self.sections.isEmpty {
                self.tableView.reloadData()
            } else {
                let lastIndex = (self.sections[self.viewModel.section].name.count - 1) < 0 ? 0 : self.sections[self.viewModel.section].name.count
                self.sections[self.viewModel.section].name = betRecords.map{ $0.gameName }
                self.sections[self.viewModel.section].betId = betRecords.map{ $0.betId }
                self.sections[self.viewModel.section].totalAmount = betRecords.map{ $0.stakes }
                self.sections[self.viewModel.section].winAmount = betRecords.map{ $0.winLoss }
                self.sections[self.viewModel.section].betStatus = betRecords.map{ $0.getBetStatus() }
                self.sections[self.viewModel.section].hasDetail = betRecords.map{ $0.hasDetails }
                self.sections[self.viewModel.section].wagerId = betRecords.map{ $0.wagerId }
                self.sections[self.viewModel.section].prededuct = betRecords.map{ $0.prededuct }
                self.tableView.beginUpdates()
                for i in 0 ..< self.sections[self.viewModel.section].name.count - lastIndex {
                    self.tableView.insertRows(at: [IndexPath(row: i + lastIndex, section: self.viewModel.section)], with: .automatic)
                }

                self.tableView.endUpdates()
            }
        }).disposed(by: disposeBag)
    }
    
    deinit {
        print("CasinoBetSummaryByDateViewController deinit")
    }
    
    private func getBetSummaryByDate() {
        viewModel.getBetSummaryByDate(localDate: selectDate!).subscribe {[weak self] (periodOfRecords) in
            for p in periodOfRecords {
                self?.sections.append(Section(periodOfRecord: p))
            }
            
            self?.sections.sort(by: { (s1, s2) -> Bool in
                return s1.sectionDate! > s2.sectionDate!
            })
            
            self?.tableView.reloadData()
        } onError: {[weak self] (error) in
            self?.handleErrors(error)
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
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
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
                   hasDetail: sections[indexPath.section].hasDetail[indexPath.row],
                   prededuct: sections[indexPath.section].prededuct[indexPath.row])
        if viewModel.section == indexPath.section && sections[indexPath.section].name.count - 2 == indexPath.row {
            viewModel.pagination.loadNextPageTrigger.onNext(())
        }
        
        cell.removeBorder()
        if indexPath.row != 0 {
            cell.addBorder(rightConstant: 25, leftConstant: 25)
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = ExpandableHeaderView()
        header.customInit(title: sections[section].sectionClass, section: section, delegate: self, date: sections[section].sectionDate)
        header.removeBorder()
        if section != 0 {
            header.addBorder()
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! ExpandableHeaderView
        view.addSubview(header.imageView)
        
        header.imageView.image = UIImage(named: "arrow-drop-down")
        header.imageView.translatesAutoresizingMaskIntoConstraints = false
        header.imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        header.imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        
        header.titleLabel.textColor = UIColor.whiteFull
        header.titleLabel.font = UIFont(name: "PingFangSC-Regular", size: 16)
        view.addSubview(header.titleLabel, constraints: [
            .constraint(.equal, \.leadingAnchor, offset: 24),
            .equal(\.centerYAnchor)
        ])
        
        header.dateTimeLabel.textColor = UIColor.textSecondaryScorpionGray
        header.dateTimeLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)
        view.addSubview(header.dateTimeLabel, constraints: [
            .equal(\.centerYAnchor)
        ])
        header.dateTimeLabel.constrain(to: header.titleLabel, constraints: [
            .equal(\.leadingAnchor, \.trailingAnchor, offset: 11)
        ])
        
    }
}


extension CasinoBetSummaryByDateViewController: ExpandableHeaderViewDelegate {
    func toggleSection(header: ExpandableHeaderView, section: Int) {
        if self.sections[section].expanded {
            self.tableView.beginUpdates()
            for i in 0 ..< self.sections[section].name.count {
                self.tableView.deleteRows(at: [IndexPath(row: i, section: section)], with: .automatic)
            }

            self.sections[section].name = []
            self.tableView.endUpdates()
        } else {
            viewModel.periodOfRecord = sections[section].periodOfRecord
            viewModel.section = section
            self.viewModel.pagination.refreshTrigger.onNext(())
        }
        
        self.sections[section].expanded = !self.sections[section].expanded
        header.imageView.image = self.sections[section].expanded ? UIImage(named: "arrow-drop-up") : UIImage(named: "arrow-drop-down")
    }
    
}
