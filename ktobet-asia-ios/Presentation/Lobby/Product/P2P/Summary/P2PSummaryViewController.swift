import RxDataSources
import RxSwift
import sharedbu
import UIKit

class P2PSummaryViewController: LobbyViewController {
  @IBOutlet weak var tableView: UITableView!
  
  private var emptyStateView: EmptyStateView!

  @Injected private(set) var viewModel: P2PBetViewModel

  private var disposeBag = DisposeBag()
  private var unfinishGameCount: Int32 = 0

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    viewModel.fetchBetSummary()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == P2PBetSummaryByDateViewController.segueIdentifier {
      if let dest = segue.destination as? P2PBetSummaryByDateViewController {
        dest.selectDate = sender as? String
      }
    }
  }
}

// MARK: - UI

extension P2PSummaryViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_my_bet"))

    tableView.setHeaderFooterDivider()
    
    setupEmptyStateView()
  }
  
  private func setupEmptyStateView() {
    emptyStateView = EmptyStateView(
      icon: UIImage(named: "No Records"),
      description: Localize.string("product_none_my_bet_record"),
      keyboardAppearance: .impossible)

    view.addSubview(emptyStateView)

    emptyStateView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func binding() {
    viewModel.betSummary
      .catch({ [weak self] error -> Observable<MyBetSummary> in
        switch error {
        case KTOError.EmptyData:
          self?.switchContent()
        default:
          self?.handleErrors(error)
        }
        return Observable.empty()
      })
      .do(onNext: { [weak self] in
        self?.switchContent($0)
      })
      .map { $0.finishedGame }
      .bind(to: tableView.rx.items) { tableView, row, element in
        let cell = tableView
          .dequeueReusableCell(
            withIdentifier: "MyBetSummaryTableViewCell",
            cellType: MyBetSummaryTableViewCell.self)
          .config(element: element)

        cell.removeBorder()

        if row != 0 {
          cell.addBorder()
        }

        return cell
      }
      .disposed(by: disposeBag)

    tableView.rx
      .modelSelected(MyBetSummary.Record.self)
      .bind { [weak self] data in
        self?.performSegue(
          withIdentifier: P2PBetSummaryByDateViewController.segueIdentifier,
          sender: "\(data.createdDateTime)")
      }
      .disposed(by: disposeBag)

    tableView.rx
      .setDelegate(self)
      .disposed(by: disposeBag)
  }

  private func switchContent(_ summary: MyBetSummary? = nil) {
    if
      let summary = summary as? SummaryAdapter,
      summary.hasGameRecords
    {
      self.tableView.isHidden = false
      self.emptyStateView.isHidden = true
    }
    else {
      self.tableView.isHidden = true
      self.emptyStateView.isHidden = false
    }
  }
}

// MARK: - UITableViewDelegate

extension P2PSummaryViewController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    indexPath.row == 0 && unfinishGameCount != 0 ? 57 : 81
  }
}

// MARK: - SummaryAdapter

class SummaryAdapter: MyBetSummary {
  var beans: [DateSummary] = []

  var hasGameRecords: Bool {
    finishedGame.count != 0
  }

  init(_ beans: [DateSummary]) {
    super.init()

    self.beans = beans
    self.unfinishGameCount = 0

    self.finishedGame = beans.map({ element in
      Record(
        count: Int(element.count),
        createdDateTime: element.createdDateTime.toDateFormatString(),
        totalStakes: element.totalStakes,
        totalWinLoss: element.totalWinLoss)
    })
  }
}
