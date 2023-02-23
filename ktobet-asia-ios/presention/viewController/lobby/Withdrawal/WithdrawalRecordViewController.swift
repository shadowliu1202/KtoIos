import RxCocoa
import RxDataSources
import RxSwift
import SharedBu
import SwiftUI
import UIKit

class WithdrawalRecordViewController: LobbyViewController {
  static let segueIdentifier = "toAllRecordSegue"

  @IBOutlet private weak var dateView: KTODateView!
  @IBOutlet private weak var filterBtn: FilterButton!
  @IBOutlet private weak var withdrawalRecordTitle: UILabel!
  @IBOutlet private weak var dateLabel: UILabel!
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var emptyView: UIView!

  private lazy var filterPersenter = WithdrawalPresenter()
  fileprivate var viewModel = Injectable.resolve(WithdrawalViewModel.self)!
  fileprivate var disposeBag = DisposeBag()
  fileprivate var isLoading = false
  fileprivate var activityIndicator = UIActivityIndicatorView(style: .large)
  fileprivate var curentFilter: [FilterItem]?
  fileprivate var withdrawalDateType: DateType = .week()

  // MARK: LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    initUI()
    getWithdrawalRecord()
    recordDataHandler()
  }

  // MARK: METHOD
  fileprivate func initUI() {
    withdrawalRecordTitle.text = Localize.string("withdrawal_log")
    tableView.delegate = self
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(activityIndicator)
    activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    dateView.callBackCondition = { [weak self] dateBegin, dateEnd, dateType in
      self?.viewModel.dateBegin = dateBegin
      self?.viewModel.dateEnd = dateEnd
      self?.withdrawalDateType = dateType
    }

    let storyboard = UIStoryboard(name: "Filter", bundle: nil)
    let bankFilterVC = storyboard
      .instantiateViewController(withIdentifier: "BankFilterConditionViewController") as! BankFilterConditionViewController
    filterBtn.set(filterPersenter)
      .set(curentFilter)
      .setGotoFilterVC(vc: bankFilterVC)
      .set { [weak self] items in
        guard let self else { return }
        self.curentFilter = items as? [TransactionItem]
        self.filterBtn.set(self.curentFilter)
        let status: [TransactionStatus] = self.filterPersenter.getConditionStatus(items as! [TransactionItem])
        self.viewModel.status = status
      }
  }

  fileprivate func getWithdrawalRecord() {
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, WithdrawalRecord>>(
      configureCell: { _, tv, _, element in
        let cell = tv
          .dequeueReusableCell(withIdentifier: String(
            describing: WithdrawRecordTableViewCell
              .self)) as! WithdrawRecordTableViewCell
        cell.setUp(data: element)
        return cell
      },
      titleForHeaderInSection: { dataSource, sectionIndex in
        dataSource[sectionIndex].model
      })

    viewModel.pagination.elements.map { records -> [SectionModel<String, WithdrawalRecord>] in
      var sectionModels: [SectionModel<String, WithdrawalRecord>] = []
      let sortedData = records.sorted(by: { $0.createDate.toDateTimeString() > $1.createDate.toDateTimeString() })
      let groupDic = Dictionary(
        grouping: sortedData,
        by: { String(format: "%02d/%02d/%02d", $0.groupDay.year, $0.groupDay.monthNumber, $0.groupDay.dayOfMonth) })
      let tupleData: [(String, [WithdrawalRecord])] = groupDic.dictionaryToTuple()
      tupleData.forEach {
        let today = Date().convertdateToUTC().toDateString()
        let sectionTitle = $0 == today ? Localize.string("common_today") : $0
        sectionModels.append(SectionModel(model: sectionTitle, items: $1))
      }

      return sectionModels.sorted(by: { $0.model > $1.model })
    }.asObservable().catchError({ [weak self] error -> Observable<[SectionModel<String, WithdrawalRecord>]> in
      self?.handleErrors(error)
      return Observable.just([])
    }).bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)

    viewModel.pagination.elements.map { $0.count != 0 }.debug().bind(to: emptyView.rx.isHidden).disposed(by: disposeBag)

    rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
      .map { _ in () }
      .bind(to: viewModel.pagination.refreshTrigger)
      .disposed(by: disposeBag)

    tableView.rx.reachedBottom
      .map { _ in () }
      .bind(to: self.viewModel.pagination.loadNextPageTrigger)
      .disposed(by: disposeBag)

    viewModel.pagination.loading.asObservable()
      .bind(to: isLoading(for: self.view))
      .disposed(by: disposeBag)
  }

  fileprivate func recordDataHandler() {
    Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(WithdrawalRecord.self))
      .bind { [weak self] indexPath, data in
        let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "WithdrawlRecordContainer") as! WithdrawlRecordContainer
        vc.displayId = data.displayId
        vc.transactionTransactionType = data.transactionTransactionType
        self?.navigationController?.pushViewController(vc, animated: true)
        self?.tableView.deselectRow(at: indexPath, animated: true)
      }.disposed(by: disposeBag)
  }

  fileprivate func isLoading(for view: UIView) -> AnyObserver<Bool> {
    Binder(view, binding: { _, isLoading in
      switch isLoading {
      case true:
        self.activityIndicator.startAnimating()
      case false:
        self.activityIndicator.stopAnimating()
      }
    }).asObserver()
  }
}

extension WithdrawalRecordViewController: UITableViewDelegate {
  func tableView(_: UITableView, willDisplayHeaderView view: UIView, forSection _: Int) {
    view.tintColor = UIColor.clear
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor.whitePure
    header.textLabel?.font = UIFont(name: "PingFangSC-Medium", size: 16.0)
  }

  func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
    32
  }
}
