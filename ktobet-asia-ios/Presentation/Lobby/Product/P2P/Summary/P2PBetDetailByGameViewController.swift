import RxSwift
import SharedBu
import SwiftUI
import UIKit

class P2PBetDetailByGameViewController: LobbyViewController {
  static let segueIdentifier = "toP2PBetDetail"
  var recordData: GameGroupedRecord?
  @IBOutlet weak var tableView: UITableView!

  var viewModel = Injectable.resolve(P2PBetViewModel.self)!
  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: recordData?.gameName)
    initUI()
    dataBinding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    tableView.setHeaderFooterDivider()
    
    tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] it in
        hasBetDetail(at: it) { toDetailPage(betID: $0) }
      })
      .disposed(by: disposeBag)
  }
  
  private func hasBetDetail(at it: IndexPath, _ callBack: (_ betID: String) -> Void) {
    guard
      let cell = tableView.cellForRow(at: it) as? BetDetailCell,
      cell.hasDetail
    else { return }
    
    callBack(cell.betDetailID)
  }

  private func toDetailPage(betID: String) {
    navigationController?.pushViewController(P2PBetDetailViewController(wagerID: betID), animated: true)
  }
  
  private func dataBinding() {
    guard let recordData else { return }
    viewModel.getBetDetail(startDate: recordData.startDate, endDate: recordData.endDate, gameId: recordData.gameId)
      .asObservable()
      .catch({ [weak self] error -> Observable<[P2PGameBetRecord]> in
        self?.handleErrors(error)
        return Observable.empty()
      })
      .bind(to: tableView.rx.items) { tableView, row, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "P2PBetDetailByGameCell", cellType: BetDetailCell.self)
          .configure(item)
        cell.removeBorder()
        if row != 0 {
          cell.addBorder(leftConstant: 30)
        }
        return cell
      }
      .disposed(by: disposeBag)
  }
}

class BetDetailCell: UITableViewCell {
  @IBOutlet weak var betIdLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var chevronIcon: UIImageView!
  
  var betDetailID = ""
  var hasDetail = false

  func configure(_ item: P2PGameBetRecord) -> Self {
    self.selectionStyle = .none
    self.betIdLabel.text = item.groupId
    betDetailID = item.wagerId
    let date = item.betTime.convertToDate()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss"
    let dateString: String = dateFormatter.string(from: date)
    self.timeLabel.text = "\(dateString)".uppercased()
    let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
    self.amountLabel.text = Localize
      .string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winLoss.abs().formatString())"
    chevronIcon.isHidden = !item.hasDetails
    hasDetail = item.hasDetails
    
    return self
  }

  func configure(_ item: ArcadeGameBetRecord) {
    self.selectionStyle = .none
    self.betIdLabel.text = item.betId
    let dateString: String = item.betTime.toTimeString()
    self.timeLabel.text = "\(dateString)".uppercased()
    let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
    self.amountLabel.text = Localize
      .string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winLoss.abs().formatString())"
  }
}
