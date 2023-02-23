import RxCocoa
import RxDataSources
import RxSwift
import SharedBu
import UIKit

class NumberGameDetailViewController: LobbyViewController {
  static let segueIdentifier = "toNumberGameBetDetail"
  @IBOutlet weak var tableView: UITableView!

  var viewModel = Injectable.resolve(NumberGameRecordViewModel.self)!
  private let disposeBag = DisposeBag()
  private var details: [NumberGameBetDetail]?

  var gameId: Int32?
  var gameName: String?
  var betDate: SharedBu.LocalDate?
  var betStatus: NumberGameSummary.CompanionStatus?
  var totalCounts: Int32?

  fileprivate var activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: gameName)
    initUI()
    dataBinding()
    summaryDataHandler()
  }

  private func initUI() {
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(activityIndicator)
    activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    self.tableView.setHeaderFooterDivider()
  }

  var tempResult: [NumberGameSummary.Bet] = []
  var tempIndex: [Int] = []
  private func dataBinding() {
    guard let status = betStatus, let date = betDate, let id = gameId else { return }
    viewModel.selectedBetStatus = status
    viewModel.selectedBetDate = date
    viewModel.selectedGameId = id
    viewModel.betPagination.elements.do(onNext: { [weak self] games in
      guard let self else { return }
      self.tempIndex = []
      if !self.tempResult.isEmpty {
        let difference = self.tempResult.difference(from: games)
        difference.forEach { game in
          if let index = self.tempResult.firstIndex(of: game) {
            self.tempIndex.append(index)
          }
        }
      }

      if games.count > self.tempResult.count {
        self.tempResult = games
      }
    }).map({ [weak self] _ -> [NumberGameSummary.Bet] in
      self?.tempResult ?? []
    }).catchError({ [weak self] error -> Observable<[NumberGameSummary.Bet]> in
      self?.handleErrors(error)
      return Observable.just([])
    }).bind(to: tableView.rx.items) { [weak self] _, row, element in
      guard let self else { return UITableViewCell() }
      let cell = self.tableView.dequeueReusableCell(withIdentifier: "SlotBetDetailCell", cellType: SlotBetDetailCell.self)
      cell.iconImageView.isHidden = false
      cell.configure(element)
      if self.tempIndex.contains(row) {
        cell.iconImageView.isHidden = true
        for view in cell.contentView.subviews {
          view.alpha = 0.4
        }
      }

      cell.removeBorder()
      if row != 0 {
        cell.addBorder(leftConstant: 24)
      }

      return cell
    }.disposed(by: disposeBag)

    rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
      .map { _ in () }
      .bind(to: viewModel.betPagination.refreshTrigger)
      .disposed(by: disposeBag)

    tableView.rx.reachedBottom
      .map { _ in () }
      .bind(to: self.viewModel.betPagination.loadNextPageTrigger)
      .disposed(by: disposeBag)

    viewModel.betPagination.loading.asObservable()
      .bind(to: isLoading(for: self.view))
      .disposed(by: disposeBag)
  }

  private func summaryDataHandler() {
    Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(NumberGameSummary.Bet.self))
      .bind { [weak self] indexPath, _ in
        guard let self else { return }
        if self.tempIndex.contains(indexPath.row) {
          Alert.shared.show(nil, Localize.string("product_bet_has_settled"), confirm: nil, cancel: nil)
          return
        }
        guard let status = self.betStatus, let date = self.betDate?.convertToDate(), let id = self.gameId else { return }
        self.viewModel.getGameBetsByDate(gameId: id, date: date, betStatus: status).subscribe { [weak self] bets in
          guard let self else { return }

          let wagerIds = bets.map { $0.wagerId }
          self.viewModel.getRecentGamesDetail(wagerIds: wagerIds)
            .subscribe { [weak self] (details: [NumberGameBetDetail]) in
              guard let self else { return }
              self.details = details
              self.performSegue(withIdentifier: NumberGameMyBetDetailViewController.segueIdentifier, sender: indexPath.row)
            } onError: { [weak self] error in
              self?.handleErrors(error)
            }.disposed(by: self.disposeBag)
        } onError: { [weak self] error in
          self?.handleErrors(error)
        }.disposed(by: self.disposeBag)
      }.disposed(by: disposeBag)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == NumberGameMyBetDetailViewController.segueIdentifier {
      if let dest = segue.destination as? NumberGameMyBetDetailViewController {
        dest.details = self.details
        if let row = sender as? Int {
          dest.selectedIndex = row
        }
      }
    }
  }

  fileprivate func isLoading(for view: UIView) -> AnyObserver<Bool> {
    Binder(view, binding: { [weak self] _, isLoading in
      guard let self else { return }
      switch isLoading {
      case true:
        self.startActivityIndicator(activityIndicator: self.activityIndicator)
      case false:
        self.stopActivityIndicator(activityIndicator: self.activityIndicator)
      }
    }).asObserver()
  }

  deinit {
    print("\(type(of: self)) deinit")
  }
}
