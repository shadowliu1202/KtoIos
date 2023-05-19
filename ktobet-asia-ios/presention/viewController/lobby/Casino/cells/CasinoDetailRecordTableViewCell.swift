import RxSwift
import SharedBu
import UIKit

class CasinoDetailRecord3TableViewCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var betIdLabel: UILabel!
  @IBOutlet weak var otherBetIdLabel: UILabel!
}

class CasinoDetailRecord2TableViewCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!

  func setup(index: Int, detail: CasinoDetail, supportLocal: SupportLocale) {
    if index == 1 {
      self.titleLabel.text = Localize.string("product_game_name_id")
      self.contentLabel.text = detail.gameName + "(\(detail.roundId))"
    }

    if index == 2 {
      self.titleLabel.text = Localize.string("product_bet_content")
      self.contentLabel.text = detail.selection
    }

    if index == 3 {
      self.titleLabel.text = Localize.string("product_bet_time")
      let date = detail.betTime.convertToDate()
      let dateFormatter = Theme.shared.getBetTimeWeekdayFormat(by: supportLocal)
      let currentDateString: String = dateFormatter.string(from: date)
      self.contentLabel.text = "\(currentDateString)"
    }

    if index == 4 {
      self.titleLabel.text = Localize.string("product_bet_amount")
      self.contentLabel.text = detail.stakes.description()
    }

    if index == 5 {
      self.titleLabel.text = Localize.string("product_bet_win_lose")
      if detail.winLoss.isPositive {
        self.contentLabel.text = String(format: Localize.string("product_winning_amount"), detail.winLoss.description())
        self.contentLabel.textColor = UIColor.statusSuccess
      }
      else {
        self.contentLabel.text = String(
          format: Localize.string("product_losing_amount"),
          detail.winLoss.formatString(.none))
      }
    }
  }
}
