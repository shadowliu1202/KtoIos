import RxSwift
import SharedBu
import UIKit

class CasinoDetailViewController: LobbyViewController {
  static let segueIdentifier = "toCasinoDetailViewController"
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var scrollView: UIScrollView!
  @IBOutlet private weak var betResultTitleLabel: UILabel!
  @IBOutlet private weak var backgroundView: UIView!
  @IBOutlet private weak var tableViewHeightConstant: NSLayoutConstraint!

  private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private var viewModel = Injectable.resolve(CasinoViewModel.self)!
  private var disposeBag = DisposeBag()

  var wagerId: String! = ""
  var recordDetail: CasinoDetail?

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("balancelog_wager_detail"))
    tableView.dataSource = self
    tableView.delegate = self
    tableView.setHeaderFooterDivider(footerHeight: 0)
    viewModel.getWagerDetail(wagerId: wagerId).subscribe { [weak self] detail in
      guard let self, let detail else { return }
      self.recordDetail = detail
      self.tableView.reloadData()
      self.displayGameResult(detail)
    } onFailure: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  override func viewDidLayoutSubviews() {
    self.tableViewHeightConstant.constant = self.tableView.contentSize.height
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func displayGameResult(_ detail: CasinoDetail) {
    switch detail.status {
    case .canceled,
         .void_:
      createCancelView()
    case .bet,
         .settled:
      createResultView(gameResult: detail.gameResult)
    default:
      break
    }
  }

  private func createCancelView() {
    let cancelTitleLabel = UILabel()
    cancelTitleLabel.text = Localize.string("common_cancel")
    cancelTitleLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)
    cancelTitleLabel.textColor = UIColor.whitePure
    scrollView.addSubview(cancelTitleLabel)
    cancelTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    cancelTitleLabel.leadingAnchor.constraint(equalTo: betResultTitleLabel.leadingAnchor, constant: 0).isActive = true
    cancelTitleLabel.topAnchor.constraint(equalTo: betResultTitleLabel.bottomAnchor, constant: 4).isActive = true
    addResultBottomLine()
  }

  private func addResultBottomLine() {
    let bottomBorderLine = UIView()
    bottomBorderLine.backgroundColor = UIColor.gray3C3E40
    scrollView.addSubview(bottomBorderLine)
    bottomBorderLine.translatesAutoresizingMaskIntoConstraints = false
    bottomBorderLine.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, multiplier: 1).isActive = true
    bottomBorderLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
    bottomBorderLine.topAnchor.constraint(equalTo: betResultTitleLabel.bottomAnchor, constant: 40).isActive = true
    bottomBorderLine.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor).isActive = true
  }
}

// MARK: - TableView Delegate, DataSource

extension CasinoDetailViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    self.recordDetail == nil ? 0 : 6
  }

  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let detail = recordDetail else { return 0 }
    if indexPath.row == 0 || (indexPath.row == 4 && detail.prededuct != AccountCurrency.zero()) {
      return 90
    }
    else {
      return 70
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let detail = recordDetail else { return UITableViewCell() }
    if indexPath.row == 0 || (detail.prededuct != AccountCurrency.zero() && indexPath.row == 4) {
      if
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "CasinoDetailRecord3Cell",
          for: indexPath) as? CasinoDetailRecord3TableViewCell
      {
        cell.removeBorder()
        if indexPath.row == 0 {
          cell.betIdLabel.text = detail.betId
          cell.otherBetIdLabel.text = detail.otherId
        }

        if indexPath.row == 4 {
          cell.titleLabel.text = Localize.string("product_bet_amount")
          cell.betIdLabel.text = detail.stakes.description()
          cell.otherBetIdLabel.text = Localize.string("product_prededuct") + " " + detail.prededuct.description()
          cell.otherBetIdLabel.font = UIFont(name: "PingFangSC-Semibold", size: 14)
          cell.otherBetIdLabel.textColor = UIColor.whitePure
        }

        if indexPath.row != 0 {
          cell.addBorder(rightConstant: 30, leftConstant: 30)
        }

        return cell
      }
    }
    else {
      if
        let cell = tableView.dequeueReusableCell(
          withIdentifier: "CasinoDetailRecord2Cell",
          for: indexPath) as? CasinoDetailRecord2TableViewCell
      {
        cell.setup(index: indexPath.row, detail: detail, supportLocal: localStorageRepo.getSupportLocale())

        if indexPath.row != 0 {
          cell.addBorder(rightConstant: 30, leftConstant: 30)
        }
        if indexPath.row == 5 {
          cell.addBorder(.bottom, rightConstant: 30, leftConstant: 30)
        }
        return cell
      }
    }

    return UITableViewCell()
  }
}

// MARK: - Create Result View

extension CasinoDetailViewController {
  private func createResultView(gameResult: CasinoGameResult) {
    let builder: CasinoResultBuilder

    switch gameResult {
    case let twoSide as TwoSideGameResult:
      builder = TwoSideGameResultBuilder(result: twoSide)

    case let sicbo as CasinoGameResult.Sicbo:
      builder = SicboGameResultBuilder(sicbo: sicbo)

    case let roulette as CasinoGameResult.Roulette:
      builder = RouletteGameResultBuilder(roulette: roulette)

    case let bullbull as BullBullGameResult:
      builder = BullBullGameResultBuilder(result: bullbull)

    case let hasFirstCard as HasFirstCardGameResult:
      builder = HasFirstCardGameResultBuilder(result: hasFirstCard)

    case let bullFight as CasinoGameResult.BullFight:
      builder = BullFightGameResultBuilder(result: bullFight)

    case let blackjack as CasinoGameResult.BlackjackN2:
      builder = BlackjackGameResultBuilder(result: blackjack)

    default:
      addResultBottomLine()
      return
    }

    builder.build(to: backgroundView)
  }
}
