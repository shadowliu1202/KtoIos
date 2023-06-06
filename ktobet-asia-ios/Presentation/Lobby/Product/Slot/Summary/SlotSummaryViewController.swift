import RxDataSources
import RxSwift
import SharedBu
import SnapKit
import UIKit

class SlotSummaryViewController: LobbyViewController {
  @IBOutlet private weak var tableView: UITableView!

  private var emptyStateView: EmptyStateView!

  private var viewModel = Injectable.resolve(SlotBetViewModel.self)!
  private var disposeBag = DisposeBag()
  private var unfinishGameCount: Int32 = 0

  override func viewDidLoad() {
    super.viewDidLoad()
     
    initUI()
    bindingSummaryData()
    summaryDataHandler()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.fetchBetSummary()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_my_bet"))
    
    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    tableView.setHeaderFooterDivider()

    initEmptyStateView()
  }
  
  private func initEmptyStateView() {
    emptyStateView = EmptyStateView(
      icon: UIImage(named: "No Records"),
      description: Localize.string("product_none_my_bet_record"),
      keyboardAppearance: .impossible)

    view.addSubview(emptyStateView)

    emptyStateView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func bindingSummaryData() {
    viewModel.betSummary
      .catch({ [weak self] error -> Observable<BetSummary> in
        switch error {
        case KTOError.EmptyData:
          self?.switchContent()
        default:
          self?.handleErrors(error)
        }
        return Observable.empty()
      })
      .map { [weak self] betSummary -> [DateSummary] in
        guard let self else { return [] }
        self.switchContent(betSummary)
        var addUnFinishGame = betSummary.finishedGame
        if self.hasUnsettleGameRecords(summary: betSummary) {
          addUnFinishGame.insert(
            DateSummary(
              totalStakes: 0.toAccountCurrency(),
              totalWinLoss: 0.toAccountCurrency(),
              createdDateTime: SharedBu.LocalDate(year: 0, monthNumber: 1, dayOfMonth: 1),
              count: 0),
            at: 0)
        }
        return addUnFinishGame
      }.bind(to: tableView.rx.items) { [weak self] tableView, row, element in
        guard let self else { return UITableViewCell() }
        if self.unfinishGameCount != 0, row == 0 {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: "unFinishGameTableViewCell",
            cellType: UnFinishGameTableViewCell.self)
          cell.recordCountLabel.text = Localize.string("product_count_bet_record", "\(self.unfinishGameCount)")
          cell.removeBorder()
          if row != 0 {
            cell.addBorder()
          }

          return cell
        }
        else {
          let cell = tableView.dequeueReusableCell(
            withIdentifier: "CasinoSummaryTableViewCell",
            cellType: CasinoSummaryTableViewCell.self)
          cell.setup(element: element)
          cell.removeBorder()
          if row != 0 {
            cell.addBorder()
          }

          return cell
        }
      }.disposed(by: disposeBag)
  }

  private func switchContent(_ summary: BetSummary? = nil) {
    if let items = summary, hasGameRecords(summary: items) || hasUnsettleGameRecords(summary: items) {
      self.tableView.isHidden = false
      self.emptyStateView.isHidden = true
    }
    else {
      self.tableView.isHidden = true
      self.emptyStateView.isHidden = false
    }
  }

  private func summaryDataHandler() {
    Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(DateSummary.self))
      .bind { [weak self] indexPath, data in
        guard let self else { return }
        if indexPath.row == 0, self.unfinishGameCount != 0 {
          self.performSegue(withIdentifier: SlotUnsettleRecordsViewController.segueIdentifier, sender: nil)
        }
        else {
          self.performSegue(
            withIdentifier: SlotBetSummaryByDateViewController.segueIdentifier,
            sender: "\(data.createdDateTime)")
        }
      }.disposed(by: disposeBag)
  }

  private func hasUnsettleGameRecords(summary: BetSummary) -> Bool {
    unfinishGameCount = summary.unFinishedGames
    return summary.unFinishedGames > 0
  }

  private func hasGameRecords(summary: BetSummary) -> Bool {
    summary.finishedGame.count != 0
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == SlotBetSummaryByDateViewController.segueIdentifier {
      if let dest = segue.destination as? SlotBetSummaryByDateViewController {
        dest.selectDate = sender as? String
      }
    }
  }
}

extension SlotSummaryViewController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    indexPath.row == 0 && unfinishGameCount != 0 ? 57 : 81
  }
}
