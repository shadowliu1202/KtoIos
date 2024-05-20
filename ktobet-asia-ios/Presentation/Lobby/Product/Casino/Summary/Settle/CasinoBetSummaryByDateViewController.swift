import RxCocoa
import RxSwift
import sharedbu
import UIKit

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
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: .back,
            title: selectDate?.replacingOccurrences(of: "-", with: "/"))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setHeaderFooterDivider(headerColor: UIColor.greyScaleDefault)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        viewModel.getBetSummaryByDate(localDate: selectDate!)
            .do(onSuccess: { [weak self] in
                self?.setupTableView(periodOfRecords: $0)
            })
            .asObservable()
            .flatMap { [unowned self] _ in
                self.bindEachPeriodPagination()
            }
            .subscribe(onNext: { [unowned self] periodOfRecord, betRecords in
                if let sectionIndex = sections.firstIndex(where: { $0.periodOfRecord == periodOfRecord }) {
                    appendBetRecordToSection(sectionIndex, betRecords: betRecords)
          
                    let rowCountOfSection = self.tableView.numberOfRows(inSection: sectionIndex)
          
                    insertRowsWithAnimation(
                        recordCount: betRecords.count,
                        offsetIndex: rowCountOfSection,
                        sectionIndex: sectionIndex)
                }
            })
            .disposed(by: disposeBag)
    }
  
    private func setupTableView(periodOfRecords: [PeriodOfRecord]) {
        sections = periodOfRecords.map { Section(periodOfRecord: $0) }

        sections.sort(by: { s1, s2 -> Bool in
            s1.sectionDate! > s2.sectionDate!
        })

        tableView.reloadData()
    }
  
    private func bindEachPeriodPagination() -> Observable<(PeriodOfRecord, [BetRecord])> {
        Observable
            .from(viewModel.periodPaginationDic)
            .flatMap { (key: PeriodOfRecord, value: Pagination<BetRecord>) in
                value.elements.map { betRecords in
                    (key, betRecords)
                }
            }
    }
  
    private func appendBetRecordToSection(_ index: Int, betRecords: [BetRecord]) {
        sections[index].betRecord = betRecords.map { Section.Record(betRecord: $0) }
    }
  
    private func insertRowsWithAnimation(recordCount: Int, offsetIndex: Int, sectionIndex: Int) {
        self.tableView.beginUpdates()
    
        for i in 0..<recordCount - offsetIndex {
            self.tableView.insertRows(
                at: [IndexPath(row: i + offsetIndex, section: sectionIndex)],
                with: .automatic)
        }

        self.tableView.endUpdates()
    }
}

extension CasinoBetSummaryByDateViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].betRecord.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! BetRecordTableViewCell
        let betRecord = sections[indexPath.section].betRecord[indexPath.row]
        cell.setup(
            name: betRecord.name,
            betId: betRecord.betId,
            totalAmount: betRecord.totalAmount,
            winAmount: betRecord.winAmount,
            betStatus: betRecord.betStatus,
            hasDetail: betRecord.hasDetail,
            prededuct: betRecord.prededuct)
    
        let isSecondLastRowOfSection = sections[indexPath.section].betRecord.count - 2 == indexPath.row
    
        if
            self.sections[indexPath.section].expanded,
            isSecondLastRowOfSection
        {
            viewModel.periodPaginationDic[sections[indexPath.section].periodOfRecord]?.loadNextPageTrigger.onNext(())
        }

        cell.removeBorder()
        if indexPath.row != 0 {
            cell.addBorder(leftConstant: 30)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wager = sections[indexPath.section].betRecord[indexPath.row]
    
        if wager.hasDetail {
            navigationController?.pushViewController(CasinoBetDetailViewController(wagerID: wager.wagerId), animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sections[indexPath.section].expanded {
            return UITableView.automaticDimension
        }
        else {
            return 0
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        ExpandableHeaderView(
            title: sections[section].sectionClass,
            section: section,
            total: sections.count,
            expanded: sections[section].expanded,
            delegate: self,
            date: sections[section].sectionDate)
    }
}

extension CasinoBetSummaryByDateViewController: ExpandableHeaderViewDelegate {
    func toggleSection(header _: ExpandableHeaderView, section: Int, expanded: Bool) {
        if self.sections[section].expanded {
            self.tableView.beginUpdates()
            for i in 0..<self.sections[section].betRecord.count {
                self.tableView.deleteRows(at: [IndexPath(row: i, section: section)], with: .none)
            }

            self.sections[section].betRecord = []
            self.tableView.endUpdates()
        }
        else {
            viewModel.periodPaginationDic[sections[section].periodOfRecord]?.refreshTrigger.onNext(())
        }

        self.sections[section].expanded = expanded
    }
}

extension CasinoBetSummaryByDateViewController {
    struct Section {
        var webGames: [WebGame] = []
        var gameId: [Int32] = []
        var sectionClass: String!
        var sectionDate: String?
        var expanded = false
        var periodOfRecord: PeriodOfRecord!
        var betRecord: [Record] = []

        init() { }

        init(periodOfRecord: PeriodOfRecord) {
            self.periodOfRecord = periodOfRecord
            let dateTime = "( " +
                String(
                    format: "%02d:%02d ~ %02d:%02d",
                    self.periodOfRecord.startDate.hour,
                    self.periodOfRecord.startDate.minute,
                    self.periodOfRecord.endDate.hour,
                    self.periodOfRecord.endDate.minute) + " )"
            self.sectionDate = dateTime
            self.sectionClass = self.periodOfRecord.lobbyName
        }
    
        struct Record {
            let name: String
            let betId: String
            let totalAmount: AccountCurrency
            let winAmount: AccountCurrency
            let betStatus: BetStatus
            let hasDetail: Bool
            let wagerId: String
            let prededuct: AccountCurrency
      
            init(betRecord: BetRecord) {
                self.name = betRecord.gameName
                self.betId = betRecord.betId
                self.totalAmount = betRecord.stakes
                self.winAmount = betRecord.winLoss
                self.betStatus = betRecord.getBetStatus()
                self.hasDetail = betRecord.hasDetails
                self.wagerId = betRecord.wagerId
                self.prededuct = betRecord.prededuct
            }
        }
    }
}
