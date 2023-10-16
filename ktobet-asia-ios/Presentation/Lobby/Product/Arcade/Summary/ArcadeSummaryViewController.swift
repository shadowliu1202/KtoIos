import RxDataSources
import RxSwift
import sharedbu
import UIKit

class ArcadeSummaryViewController: LobbyViewController {
  @IBOutlet private weak var tableView: UITableView!
  
  private var emptyStateView: EmptyStateView!

  private var viewModel = Injectable.resolve(ArcadeRecordViewModel.self)!
  private var disposeBag = DisposeBag()
  private var unfinishGameCount: Int32 = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_my_bet"))
    initUI()
    bindingSummaryData()
    summaryDataHandler()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
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
    let summaryData = self.rx.viewWillAppear.flatMap({ [unowned self] _ in
      self.viewModel.getBetSummary().asObservable()
    }).share(replay: 1)

    summaryData.catch({ [weak self] error -> Observable<[DateSummary]> in
      self?.handleErrors(error)
      return Observable.just([])
    }).do(onNext: { [weak self] data in
      if data.count == 0 {
        self?.switchContent()
      }
    }).map({ dateSummary -> [MyBetSummary.Record] in
      SummaryAdapter(dateSummary).finishedGame
    }).bind(to: tableView.rx.items) { tableView, row, element in
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "MyBetSummaryTableViewCell",
        cellType: MyBetSummaryTableViewCell.self).config(element: element)
      cell.removeBorder()
      if row != 0 {
        cell.addBorder()
      }

      return cell
    }.disposed(by: disposeBag)
  }

  private func switchContent(_ summary: MyBetSummary? = nil) {
    if let items = summary, hasGameRecords(summary: items) {
      self.tableView.isHidden = false
      self.emptyStateView.isHidden = true
    }
    else {
      self.tableView.isHidden = true
      self.emptyStateView.isHidden = false
    }
  }

  private func summaryDataHandler() {
    Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(MyBetSummary.Record.self)).bind { [weak self] _, data in
      self?.viewModel.selectedLocalDate = data.createdDateTime
      self?.performSegue(withIdentifier: ArcadeBetSummaryByDateViewController.segueIdentifier, sender: nil)
    }.disposed(by: disposeBag)
  }

  private func hasGameRecords(summary: MyBetSummary) -> Bool {
    summary.finishedGame.count != 0
  }

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if segue.identifier == ArcadeBetSummaryByDateViewController.segueIdentifier {
      if let dest = segue.destination as? ArcadeBetSummaryByDateViewController {
        dest.viewModel = self.viewModel
      }
    }
  }
}

extension ArcadeSummaryViewController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    indexPath.row == 0 && unfinishGameCount != 0 ? 57 : 81
  }
}
