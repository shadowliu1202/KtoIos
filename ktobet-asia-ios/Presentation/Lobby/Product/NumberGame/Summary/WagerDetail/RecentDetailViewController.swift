import RxCocoa
import RxSwift
import sharedbu
import UIKit

class RecentDetailViewController: LobbyViewController {
  var page: Int?
  var detailItem: NumberGameBetDetail?
  private var resultViewHeight: CGFloat = 0

  @IBOutlet weak var tableView: UITableView!

  private let playerConfiguration = Injectable.resolve(PlayerConfiguration.self)!

  override func viewDidLoad() {
    super.viewDidLoad()
    initUI()
  }

  private func initUI() {
    tableView.estimatedRowHeight = 81.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.dataSource = self
    tableView.setHeaderFooterDivider()
    if let results = detailItem?.resultList, results.count > 0 {
      createNumberResultView(results)
    }
    tableView.tableFooterView?.frame.size.height += resultViewHeight
  }

  private func createNumberResultView(_ results: [KotlinInt]) {
    let resultView = UIView(frame: .zero)
    resultView.backgroundColor = UIColor.clear
    tableView.tableFooterView?.addSubview(resultView, constraints: [
      .constraint(.equal, \.trailingAnchor, offset: 0),
      .constraint(.equal, \.leadingAnchor, offset: 0),
      .constraint(.equal, \.topAnchor, offset: 0),
      .constraint(.equal, \.bottomAnchor, offset: 96)
    ])

    let label = UILabel()
    label.textAlignment = .left
    label.font = UIFont(name: "PingFangSC-Medium", size: 14)
    label.textColor = UIColor.textPrimary
    label.text = Localize.string("product_draw_result")
    resultView.addSubview(label, constraints: [
      .constraint(.equal, \.trailingAnchor, offset: 24),
      .constraint(.equal, \.leadingAnchor, offset: 24),
      .constraint(.equal, \.topAnchor, offset: 14),
      .constraint(.equal, \.heightAnchor, length: 20)
    ])

    let chunks = results.chunked(into: 5)
    for (index, results) in chunks.enumerated() {
      let oneRow = UIStackView(frame: .zero)
      oneRow.axis = .horizontal
      oneRow.alignment = .center
      oneRow.distribution = .equalSpacing
      oneRow.spacing = 20
      results.forEach { num in
        let ball = self.makeBall(num)
        oneRow.addArrangedSubview(ball)
      }
      resultView.addSubview(
        oneRow,
        constraints: [.equal(\.centerXAnchor), .constraint(.equal, \.topAnchor, offset: 49 + CGFloat(index * 55))])
    }
    self.resultViewHeight = CGFloat(49 + (chunks.count * 55))
  }

  private func makeBall(_ num: KotlinInt) -> UIView {
    let circle = UIView(frame: .zero)
    circle.constrain([
      .equal(\.heightAnchor, length: 47),
      .equal(\.widthAnchor, length: 47)
    ])
    circle.backgroundColor = UIColor.primaryDefault
    circle.cornerRadius = 47 / 2
    let label = UILabel()
    label.font = UIFont(name: "PingFangSC-Semibold", size: 14)
    label.textColor = UIColor.greyScaleWhite
    label.text = "\(num.intValue)"
    circle.addSubview(label, constraints: .center)
    return circle
  }
}

extension RecentDetailViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    detailItem == nil ? 0 : 6
  }

  func tableView(_: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let item = detailItem else { return UITableViewCell() }
    let cell = self.tableView.dequeueReusableCell(withIdentifier: "RecentDetailCell", cellType: RecentDetailCell.self)
      .configure(index: indexPath.row, data: item, supportLocal: playerConfiguration.supportLocale)
    cell.removeBorder()
    if indexPath.row != 0 {
      cell.addBorder(rightConstant: 30, leftConstant: 30)
    }

    return cell
  }
}

class RecentDetailCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var subDescriptionLabel: UILabel!

  func configure(index: Int, data: NumberGameBetDetail, supportLocal: SupportLocale) -> Self {
    if index == 0 {
      setTilte(key: "product_bet_id")
      setValue(data.displayId)
      subDescriptionLabel.text = data.traceId
    }
    else if index == 1 {
      setTilte(key: "product_number_game_name_id")
      setValue(data.gameName + " (\(data.matchMethod))")
    }
    else if index == 2 {
      setTilte(key: "product_bet_content")
      setValue(data.betContent.joined(separator: "\n"))
    }
    else if index == 3 {
      setTilte(key: "product_bet_time")
      let date = data.betTime.convertToDate()
      let dateFormatter = Theme.shared.getBetTimeWeekdayFormat(by: supportLocal)
      let currentDateString: String = dateFormatter.string(from: date)
      setValue(currentDateString)
    }
    else if index == 4 {
      setTilte(key: "product_bet_amount")
      setValue(data.stakes.description())
    }
    else if index == 5 {
      setTilte(key: "common_status")
      let status = data.status
      let betStatus = status.LocalizeString
      setValue(betStatus)
      if
        status is NumberGameBetDetail.BetStatusSettledWinLose,
        (status as! NumberGameBetDetail.BetStatusSettledWinLose).winLoss.isPositive
      {
        descriptionLabel.textColor = UIColor.statusSuccess
      }
    }
    return self
  }

  private func setTilte(key: String) {
    titleLabel.text = Localize.string(key)
  }

  private func setValue(_ txt: String) {
    if txt.isEmpty {
      descriptionLabel.text = " "
    }
    else {
      descriptionLabel.text = txt
    }
  }
}
