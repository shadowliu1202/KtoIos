import RxSwift
import SharedBu
import UIKit

class P2PBetSummaryByDateViewController: LobbyViewController {
  static let segueIdentifier = "toP2PBetSummaryByDate"
  var selectDate: String? = ""
  var viewModel = Injectable.resolve(P2PBetViewModel.self)!
  private var disposeBag = DisposeBag()

  @IBOutlet private weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: selectDate)
    initUI()
    dataBinding()
  }

  deinit {
    print("\(type(of: self)) deinit")
  }

  private func initUI() {
    tableView.setHeaderFooterDivider()
    tableView.estimatedRowHeight = 124.0
    tableView.rowHeight = UITableView.automaticDimension
  }

  private func dataBinding() {
    guard let selectDate else { return }
    viewModel.betSummaryByDate(localDate: selectDate).asObservable()
      .catchError({ [weak self] error -> Observable<[GameGroupedRecord]> in
        self?.handleErrors(error)
        return Observable.empty()
      }).bind(to: tableView.rx.items) { tableView, row, item in
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "P2PBetSummaryByDateCell",
          cellType: P2PBetSummaryByDateCell.self).configure(item)
        cell.removeBorder()
        if row != 0 {
          cell.addBorder(leftConstant: 30)
        }

        return cell
      }.disposed(by: disposeBag)
    tableView.rx.modelSelected(GameGroupedRecord.self).bind { [unowned self] data in
      self.performSegue(withIdentifier: P2PBetDetailViewController.segueIdentifier, sender: data)
    }.disposed(by: disposeBag)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == P2PBetDetailViewController.segueIdentifier {
      if let dest = segue.destination as? P2PBetDetailViewController {
        dest.recordData = sender as? GameGroupedRecord
      }
    }
  }
}

class P2PBetSummaryByDateCell: UITableViewCell {
  @IBOutlet weak var gameLabel: UILabel!
  @IBOutlet weak var betCountLabel: UILabel!
  @IBOutlet weak var betAmountLabel: UILabel!
  @IBOutlet weak var betWinLossLabel: UILabel!
  @IBOutlet weak var gameImgView: UIImageView!

  override func prepareForReuse() {
    super.prepareForReuse()
    gameImgView.sd_cancelCurrentImageLoad()
    gameImgView.image = nil
  }

  func configure(_ item: GameGroupedRecord) -> Self {
    gameImgView.sd_setImage(url: URL(string: item.thumbnail.url()))
    gameLabel.text = item.gameName
    betCountLabel.text = Localize.string("product_count_bet_record", "\(item.recordsCount)")
    let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
    betAmountLabel.text = Localize.string("product_total_bet", item.stakes.description())
    betWinLossLabel.text = status + " \(item.winLoss.formatString(.none))"
    return self
  }
}
