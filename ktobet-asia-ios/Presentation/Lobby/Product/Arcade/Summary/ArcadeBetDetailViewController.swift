import RxSwift
import sharedbu
import UIKit

class ArcadeBetDetailViewController: LobbyViewController {
  static let segueIdentifier = "toArcadeBetDetail"
  @IBOutlet weak var tableView: UITableView!

  var viewModel: ArcadeRecordViewModel!
  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: viewModel.selectedRecord?.gameName)
    initUI()
    dataBinding()
  }

  deinit {
    viewModel.recordDetailPagination.elements.accept([])
  }

  private func initUI() {
    tableView.setHeaderFooterDivider()
  }

  private func dataBinding() {
    viewModel.recordDetailPagination.elements
      .catch({ [weak self] error -> Observable<[ArcadeGameBetRecord]> in
        self?.handleErrors(error)
        return Observable<[ArcadeGameBetRecord]>.just([])
      }).bind(to: tableView.rx.items) { tableView, row, element in
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArcadeBetDetailCell", cellType: BetDetailCell.self)
        cell.configure(element)
        cell.removeBorder()
        if row != 0 {
          cell.addBorder(leftConstant: 30)
        }

        return cell
      }.disposed(by: disposeBag)

    rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
      .map { _ in () }
      .bind(to: viewModel.recordDetailPagination.refreshTrigger)
      .disposed(by: disposeBag)

    tableView.rx.reachedBottom
      .map { _ in () }
      .bind(to: self.viewModel.recordDetailPagination.loadNextPageTrigger)
      .disposed(by: disposeBag)
  }
}
