import RxCocoa
import RxDataSources
import RxSwift
import SharedBu
import UIKit

class SettleViewController: UIViewController {
  @IBOutlet private weak var noDataView: UIView!
  @IBOutlet private weak var tableView: UITableView!

  var viewModel: NumberGameRecordViewModel!
  private var disposeBag = DisposeBag()
  private var dataSource = BehaviorRelay(value: [NumberGameSummary.Date]())

  override func viewDidLoad() {
    super.viewDidLoad()
    initUI()
    summaryDataHandler()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    bindingSummaryData()
  }

  private func initUI() {
    tableView.rx.setDelegate(self).disposed(by: disposeBag)
    tableView.setHeaderFooterDivider(headerHeight: 87)
    dataSource.do(onNext: { [weak self] records in
      self?.switchContent(records.count)
    }).catchError({ [weak self] error -> Observable<[NumberGameSummary.Date]> in
      self?.handleErrors(error)
      return Observable.just([])
    }).bind(to: tableView.rx.items) { [weak self] _, row, element in
      guard let self else { return UITableViewCell() }
      let cell = self.tableView.dequeueReusableCell(
        withIdentifier: "CasinoSummaryTableViewCell",
        cellType: CasinoSummaryTableViewCell.self)
      cell.setup(element: element)
      cell.removeBorder()
      if row != 0 {
        cell.addBorder(leftConstant: 30)
      }

      return cell
    }.disposed(by: disposeBag)
  }

  private func bindingSummaryData() {
    viewModel.settled.subscribe { [weak self] data in
      self?.dataSource.accept(data)
    } onError: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  private func switchContent(_ count: Int) {
    if count != 0 {
      self.tableView.isHidden = false
      self.noDataView.isHidden = true
    }
    else {
      self.tableView.isHidden = true
      self.noDataView.isHidden = false
    }
  }

  private func summaryDataHandler() {
    Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(NumberGameSummary.Date.self))
      .bind { [weak self] _, data in
        guard let self else { return }
        let parameter = (data.betDate, NumberGameSummary.CompanionStatus.settled)
        self.performSegue(withIdentifier: NumberGameMyBetGameGroupedViewController.segueIdentifier, sender: parameter)
      }.disposed(by: disposeBag)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == NumberGameMyBetGameGroupedViewController.segueIdentifier {
      if let dest = segue.destination as? NumberGameMyBetGameGroupedViewController {
        let parameter = sender as! (betDate: SharedBu.LocalDate, status: NumberGameSummary.CompanionStatus)
        dest.betDate = parameter.betDate
        dest.betStatus = parameter.status
      }
    }
  }

  deinit {
    print("\(type(of: self)) deinit")
  }
}

extension SettleViewController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    81
  }
}
