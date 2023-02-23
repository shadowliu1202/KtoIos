import RxSwift
import SDWebImage
import SharedBu
import UIKit

class SlotBetSummaryByDateViewController: LobbyViewController {
  static let segueIdentifier = "toSlotBetSummaryByDate"
  var selectDate: String? = ""
  var viewModel = Injectable.resolve(SlotBetViewModel.self)!
  private var disposeBag = DisposeBag()

  @IBOutlet private weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: selectDate?.replacingOccurrences(of: "-", with: "/"))
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
      .catchError({ [weak self] error -> Observable<[SlotGroupedRecord]> in
        self?.handleErrors(error)
        return Observable.just([])
      }).bind(to: tableView.rx.items) { tableView, row, item in
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "SlotBetSummaryByDateCell",
          cellType: BetSummaryByDateCell.self).configure(item)
        cell.removeBorder()
        if row != 0 {
          cell.addBorder(leftConstant: 30)
        }

        return cell
      }.disposed(by: disposeBag)
    tableView.rx.modelSelected(SlotGroupedRecord.self).bind { [unowned self] data in
      self.performSegue(withIdentifier: SlotBetDetailViewController.segueIdentifier, sender: data)
    }.disposed(by: disposeBag)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == SlotBetDetailViewController.segueIdentifier {
      if let dest = segue.destination as? SlotBetDetailViewController {
        dest.recordData = sender as? SlotGroupedRecord
      }
    }
  }
}

class BetSummaryByDateCell: UITableViewCell {
  @IBOutlet weak var gameLabel: UILabel!
  @IBOutlet weak var betCountLabel: UILabel!
  @IBOutlet weak var betAmountLabel: UILabel!
  @IBOutlet weak var gameImgView: UIImageView!
  @IBOutlet weak var iconImageView: UIImageView!

  override func prepareForReuse() {
    super.prepareForReuse()
    gameImgView.sd_cancelCurrentImageLoad()
    gameImgView.image = nil
  }

  func configure(_ item: SlotGroupedRecord) -> Self {
    gameImgView.sd_setImage(url: URL(string: item.slotThumbnail.url()))
    gameLabel.text = item.gameName
    betCountLabel.text = Localize.string("product_count_bet_record", "\(item.recordCount)")
    let status = item.winloss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
    betAmountLabel.text = Localize
      .string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winloss.formatString(.none))"

    return self
  }

  func configure(_ item: GameGroupedRecord) -> Self {
    gameImgView.sd_setImage(url: URL(string: item.thumbnail.url()))
    gameLabel.text = item.gameName
    betCountLabel.text = Localize.string("product_count_bet_record", "\(item.recordsCount)")
    let status = item.winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
    betAmountLabel.text = Localize
      .string("product_total_bet", item.stakes.description()) + "  " + status + " \(item.winLoss.formatString(.none))"

    return self
  }

  func configure(_ item: NumberGameSummary.Game) {
    gameImgView.sd_setImage(url: URL(string: item.thumbnail.url()))
    gameLabel.text = item.gameName
    betCountLabel.text = Localize.string("product_count_bet_record", "\(item.totalRecords)")
    if let winLoss = item.winLoss {
      let status = winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
      betAmountLabel.text = Localize
        .string("product_total_bet", item.betAmount.description()) + "  " + status + " \(winLoss.formatString(.none))"
    }
    else {
      betAmountLabel.text = Localize.string("product_total_bet", item.betAmount.formatString(.none))
    }
  }
}
