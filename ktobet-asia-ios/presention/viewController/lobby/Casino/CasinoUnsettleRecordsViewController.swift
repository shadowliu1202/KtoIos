import RxSwift
import SharedBu
import UIKit

class CasinoUnsettleRecordsViewController: ProductsViewController {
  static let segueIdentifier = "toCasinoUnsettleRecords"
  @IBOutlet private weak var tableView: UITableView!

  private var viewModel = Injectable.resolve(CasinoViewModel.self)!
  private var disposeBag = DisposeBag()
  private var sections: [Section] = []

  lazy var unsettleGameDelegate = UnsettleGameDelegate(self)

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_unsettled_game"))
    tableView.delegate = unsettleGameDelegate
    tableView.dataSource = self
    tableView.setHeaderFooterDivider(headerColor: UIColor.greyScaleDefault)
    getUnsettledBetSummary()

    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)

    bindWebGameResult(with: viewModel)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func getUnsettledBetSummary() {
    viewModel.getUnsettledBetSummary().subscribe { [weak self] _ in
      self?.getUnsettledRecords()
    } onError: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  private func getUnsettledRecords() {
    viewModel.getUnsettledRecords().subscribe(onNext: { [weak self] dic in
      for (date, records) in dic {
        self?.sections.append(Section(
          webGames: records,
          sectionClass: date.date.toDateFormatString(),
          name: records.map { $0.gameName },
          betId: records.map { $0.betId },
          totalAmount: records.map { $0.stakes },
          expanded: false,
          gameId: records.map { $0.gameId },
          prededuct: records.map { $0.prededuct }))
      }

      self?.sections.sort(by: { s1, s2 -> Bool in
        s1.sectionClass! > s2.sectionClass!
      })

      self?.tableView.reloadData()
    }, onError: { [weak self] error in
      self?.handleErrors(error)
    }).disposed(by: disposeBag)
  }

  override func setProductType() -> ProductType {
    .casino
  }
}

extension CasinoUnsettleRecordsViewController: ProductGoWebGameVCProtocol, UnsettleTableViewDelegate {
  func getProductViewModel() -> ProductWebGameViewModelProtocol? {
    self.viewModel
  }

  func gameId(at indexPath: IndexPath) -> Int32 {
    self.sections[indexPath.section].gameId[indexPath.row]
  }

  func gameName(at indexPath: IndexPath) -> String {
    self.sections[indexPath.section].name[indexPath.row]
  }
}

extension CasinoUnsettleRecordsViewController: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in _: UITableView) -> Int {
    sections.count
  }

  func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
    CGFloat.leastNormalMagnitude
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].name.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! BetRecordTableViewCell
    cell.setupUnSettleGame(
      sections[indexPath.section].name[indexPath.row],
      betId: sections[indexPath.section].betId[indexPath.row],
      totalAmount: sections[indexPath.section].totalAmount[indexPath.row])
    cell.removeBorder()
    if indexPath.row != 0 {
      cell.addBorder(leftConstant: 30)
    }

    return cell
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
      delegate: self)
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let game = sections[indexPath.section].webGames[indexPath.row]
    viewModel.fetchGame(game)
  }
}

extension CasinoUnsettleRecordsViewController: ExpandableHeaderViewDelegate {
  func toggleSection(header _: ExpandableHeaderView, section: Int, expanded: Bool) {
    sections[section].expanded = expanded
    tableView.beginUpdates()
    for i in 0..<sections[section].name.count {
      tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .automatic)
    }

    tableView.endUpdates()
  }
}

struct Section {
  var webGames: [WebGame] = []
  var gameId: [Int32] = []
  var sectionClass: String!
  var sectionDate: String?
  var name: [String] = []
  var betId: [String] = []
  var totalAmount: [AccountCurrency] = []
  var winAmount: [AccountCurrency] = []
  var expanded = false
  var betStatus: [BetStatus] = []
  var hasDetail: [Bool] = []
  var wagerId: [String] = []
  var periodOfRecord: PeriodOfRecord!
  var prededuct: [AccountCurrency] = []

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

  init(
    webGames: [WebGame],
    sectionClass: String,
    name: [String] = [],
    betId: [String] = [],
    totalAmount: [AccountCurrency] = [],
    winAmount: [AccountCurrency] = [],
    expanded: Bool,
    sectionDate: String? = nil,
    betStatus: [BetStatus] = [],
    hasDetail: [Bool] = [],
    wagerId: [String] = [],
    gameId: [Int32] = [],
    prededuct: [AccountCurrency] = [])
  {
    self.webGames = webGames
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
    self.prededuct = prededuct
  }
}
