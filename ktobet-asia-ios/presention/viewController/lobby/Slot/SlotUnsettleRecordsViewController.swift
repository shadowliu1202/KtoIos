import RxSwift
import SharedBu
import UIKit

class SlotUnsettleRecordsViewController: ProductsViewController {
  static let segueIdentifier = "toSlotUnsettleRecords"
  var viewModel = Injectable.resolve(SlotBetViewModel.self)!
  private var disposeBag = DisposeBag()
  private var unsettleds: [SlotUnsettledSection] = []

  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet weak var emptyView: UIView!

  lazy var unsettleGameDelegate = UnsettleGameDelegate(self)

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_unsettled_game"))
    initUI()
    dataBinding()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.fetchUnsettledBetSummary()
  }

  override func gameDidDisappear() {
    super.gameDidDisappear()
    viewModel.fetchUnsettledBetSummary()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    tableView.delegate = unsettleGameDelegate
    tableView.dataSource = self
    tableView.setHeaderFooterDivider()
  }

  private func switchContent(_ games: [SlotUnsettledSection]? = nil) {
    if let items = games, items.count > 0 {
      self.tableView.isHidden = false
      self.emptyView.isHidden = true
    }
    else {
      self.tableView.isHidden = true
      self.emptyView.isHidden = false
    }
  }

  private func dataBinding() {
    viewModel.unsettledBetSummary
      .catch({ [weak self] error -> Observable<[SlotUnsettledSection]> in
        switch error {
        case KTOError.EmptyData:
          self?.switchContent()
        default:
          self?.handleErrors(error)
        }
        return Observable.just([])
      })
      .skip(1)
      .subscribe(onNext: { [weak self] (unsettleds: [SlotUnsettledSection]) in
        self?.switchContent(unsettleds)
        self?.unsettleds = unsettleds
        self?.tableView.reloadData()
      }).disposed(by: disposeBag)

    viewModel.errors()
      .subscribe(onNext: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)

    bindWebGameResult(with: viewModel)
  }

  private func fetchNextUnsettleRecords(sectionIndex: Int, rowIndex: Int = 0) {
    viewModel.fetchNextUnsettledRecords(betTime: unsettleds[sectionIndex].betTime, rowIndex)
      .subscribe(onSuccess: { [weak self] _ in
        self?.tableView.reloadData()
      }, onFailure: { [weak self] error in
        self?.handleErrors(error)
      }).disposed(by: disposeBag)
  }

  override func setProductType() -> ProductType {
    .slot
  }
}

extension SlotUnsettleRecordsViewController: ProductGoWebGameVCProtocol, UnsettleTableViewDelegate {
  func gameId(at indexPath: IndexPath) -> Int32 {
    unsettleds[indexPath.section].records[indexPath.row].gameId
  }

  func getProductViewModel() -> ProductWebGameViewModelProtocol? {
    self.viewModel
  }

  func gameName(at indexPath: IndexPath) -> String {
    self.unsettleds[indexPath.section].records[indexPath.row].gameName
  }
}

extension SlotUnsettleRecordsViewController: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in _: UITableView) -> Int {
    unsettleds.count
  }

  func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
    CGFloat.leastNormalMagnitude
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    unsettleds[section].records.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView
      .dequeueReusableCell(withIdentifier: "SlotUnsettleRecordsCell", cellType: SlotUnsettleRecordsCell.self)
      .configure(self.unsettleds[indexPath.section].records[indexPath.row])
    cell.removeBorder()
    if indexPath.row != 0 {
      cell.addBorder(leftConstant: 25)
    }

    return cell
  }

  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if unsettleds[indexPath.section].expanded {
      return 105
    }
    else {
      return 0
    }
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let unsettled: SlotUnsettledSection = unsettleds[section]
    let header = tableView.dequeueReusableCell(
      withIdentifier: "SlotUnsettleRecordHeader",
      cellType: SlotUnsettleRecordHeader.self).configure(unsettled)
    let view = header.contentView
    view.tag = section
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickHeader(_:))))
    header.bottomLine.isHidden = unsettled.expanded
    if section == unsettleds.count - 1 {
      header.bottomLine.isHidden = true
    }
    return view
  }

  @objc
  func clickHeader(_ sender: UITapGestureRecognizer) {
    guard let section = sender.view?.tag else { return }
    let unsettled: SlotUnsettledSection = self.unsettleds[section]
    unsettled.expanded.toggle()
    if unsettled.expanded == true {
      self.fetchNextUnsettleRecords(sectionIndex: section)
    }
    else {
      self.tableView.reloadData()
    }
  }

  func tableView(_ tableView: UITableView, willDisplay _: UITableViewCell, forRowAt indexPath: IndexPath) {
    if isLoadingIndexPath(tableView, indexPath), unsettleds[indexPath.section].hasNextRecord(indexPath.row) {
      self.fetchNextUnsettleRecords(sectionIndex: indexPath.section, rowIndex: indexPath.row)
    }
  }

  private func isLoadingIndexPath(_ tableView: UITableView, _ indexPath: IndexPath) -> Bool {
    let lastRowIndex = tableView.numberOfRows(inSection: indexPath.section) - 1
    return indexPath.row == lastRowIndex
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    let game = self.unsettleds[indexPath.section].records[indexPath.row]
    viewModel.fetchGame(game)
  }
}

class SlotUnsettleRecordsCell: UITableViewCell {
  @IBOutlet weak var gameLabel: UILabel!
  @IBOutlet weak var betIdLabel: UILabel!
  @IBOutlet weak var betAmountLabel: UILabel!
  @IBOutlet weak var gameImgView: UIImageView!

  override func prepareForReuse() {
    super.prepareForReuse()
    gameImgView.sd_cancelCurrentImageLoad()
    gameImgView.image = nil
  }

  func configure(_ item: SlotUnsettledRecord) -> Self {
    gameImgView.sd_setImage(url: URL(string: item.slotThumbnail.url()))
    gameLabel.text = item.gameName
    betIdLabel.text = item.betId
    betAmountLabel.text = Localize.string("product_total_bet", item.stakes.description())
    return self
  }
}

class SlotUnsettleRecordHeader: UITableViewCell {
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var arrow: UIImageView!
  @IBOutlet weak var bottomLine: UIView!

  func configure(_ item: SlotUnsettledSection) -> Self {
    dateLabel.text = item.betTime.toDateFormatString()
    arrow.image = item.expanded ? UIImage(named: "arrow-drop-up") : UIImage(named: "arrow-drop-down")
    return self
  }
}
