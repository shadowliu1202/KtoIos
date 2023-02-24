import RxSwift
import SharedBu
import UIKit

class ArcadeBetSummaryByDateViewController: LobbyViewController {
  static let segueIdentifier = "toArcadeBetSummaryByDate"
  var viewModel: ArcadeRecordViewModel!
  private var disposeBag = DisposeBag()

  @IBOutlet private weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: viewModel.selectedLocalDate)
    initUI()
    dataBinding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
    viewModel.recordByDatePagination.elements.accept([])
  }

  private func initUI() {
    tableView.setHeaderFooterDivider()
    tableView.estimatedRowHeight = 124.0
    tableView.rowHeight = UITableView.automaticDimension
  }

  private func dataBinding() {
    viewModel.recordByDatePagination.elements
      .catch({ [weak self] error -> Observable<[GameGroupedRecord]> in
        self?.handleErrors(error)
        return Observable<[GameGroupedRecord]>.just([])
      }).bind(to: tableView.rx.items) { [weak self] _, row, element in
        guard let self else { return UITableViewCell() }
        let cell = self.tableView.dequeueReusableCell(
          withIdentifier: "ArcadeBetSummaryByDateCell",
          cellType: BetSummaryByDateCell.self).configure(element)
        cell.removeBorder()
        if row != 0 {
          cell.addBorder(leftConstant: 30)
        }

        return cell
      }.disposed(by: disposeBag)

    rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
      .map { _ in () }
      .bind(to: viewModel.recordByDatePagination.refreshTrigger)
      .disposed(by: disposeBag)

    tableView.rx.reachedBottom
      .map { _ in () }
      .bind(to: self.viewModel.recordByDatePagination.loadNextPageTrigger)
      .disposed(by: disposeBag)

    tableView.rx.modelSelected(GameGroupedRecord.self).bind { [unowned self] data in
      self.viewModel.selectedRecord = data
      self.performSegue(withIdentifier: ArcadeBetDetailViewController.segueIdentifier, sender: nil)
    }.disposed(by: disposeBag)
  }

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if segue.identifier == ArcadeBetDetailViewController.segueIdentifier {
      if let dest = segue.destination as? ArcadeBetDetailViewController {
        dest.viewModel = self.viewModel
      }
    }
  }
}
