import RxDataSources
import RxSwift
import SharedBu
import UIKit

class CasinoSummaryViewController: LobbyViewController {
  @IBOutlet private weak var noDataView: UIView!
  @IBOutlet private weak var tableView: UITableView!

  private var viewModel = Injectable.resolve(CasinoViewModel.self)!
  private var disposeBag = DisposeBag()
  private var unfinishGameCount: Int32 = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_my_bet"))
    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    tableView.setHeaderFooterDivider()
    bindingSummaryData()
    summaryDataHandler()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func bindingSummaryData() {
    let betSummaryObservable = viewModel.betSummary.asObservable().share(replay: 1)
    let dateSummaryObservable = betSummaryObservable.map { [weak self] betSummary -> [DateSummary] in
      guard let self else { return [] }
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
    }

    betSummaryObservable.subscribe(onNext: { [weak self] betSummary in
      guard let self else { return }
      self.unfinishGameCount = betSummary.unFinishedGames
      if !self.hasUnsettleGameRecords(summary: betSummary), !self.hasGameRecords(summary: betSummary) {
        self.noDataView.isHidden = false
        self.tableView.isHidden = true
      }
    }).disposed(by: disposeBag)

    dateSummaryObservable.catch({ [weak self] error -> Observable<[DateSummary]> in
      self?.handleErrors(error)
      return Observable.just([])
    }).bind(to: tableView.rx.items) { [weak self] tableView, row, element in
      guard let self else { return UITableViewCell() }
      let indexPath = IndexPath(row: row, section: 0)
      if self.unfinishGameCount != 0, row == 0 {
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "unFinishGameTableViewCell",
          for: indexPath) as! UnFinishGameTableViewCell
        cell.recordCountLabel.text = String(
          format: Localize.string("product_count_bet_record"),
          "\(self.unfinishGameCount.formattedWithSeparator)")
        return cell
      }
      else {
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "CasinoSummaryTableViewCell",
          for: indexPath) as! CasinoSummaryTableViewCell
        cell.setup(element: element)
        cell.removeBorder()
        if row != 0 {
          cell.addBorder()
        }

        return cell
      }
    }.disposed(by: disposeBag)
  }

  private func summaryDataHandler() {
    Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(DateSummary.self))
      .bind { [weak self] indexPath, data in
        guard let self else { return }
        if indexPath.row == 0, self.unfinishGameCount != 0 {
          self.performSegue(withIdentifier: CasinoUnsettleRecordsViewController.segueIdentifier, sender: nil)
        }
        else {
          self.performSegue(
            withIdentifier: CasinoBetSummaryByDateViewController.segueIdentifier,
            sender: "\(data.createdDateTime)")
        }

        self.tableView.deselectRow(at: indexPath, animated: true)
      }.disposed(by: disposeBag)
  }

  private func hasUnsettleGameRecords(summary: BetSummary) -> Bool {
    summary.unFinishedGames > 0
  }

  private func hasGameRecords(summary: BetSummary) -> Bool {
    summary.finishedGame.count != 0
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == CasinoBetSummaryByDateViewController.segueIdentifier {
      if let dest = segue.destination as? CasinoBetSummaryByDateViewController {
        dest.selectDate = sender as? String
      }
    }
  }
}

extension CasinoSummaryViewController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    indexPath.row == 0 && unfinishGameCount != 0 ? 57 : 81
  }
}
