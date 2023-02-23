import UIKit

class MyBetSummaryTableViewCell: UITableViewCell {
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var recordCountLabel: UILabel!
  @IBOutlet weak var betAmountLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }

  func config(element: Record) -> UITableViewCell {
    self.selectionStyle = .none

    recordCountLabel.text = String(
      format: Localize.string("product_count_bet_record"),
      "\(element.count.formattedWithSeparator)")
    dateLabel.text = displayDate(element.createdDateTime)
    let status = element.totalWinLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
    betAmountLabel.text = String(
      format: Localize.string("product_total_bet"),
      element.totalStakes.description() + "  " + status + " " + element.totalWinLoss.formatString(.none))

    return self
  }

  private func displayDate(_ createdDateTime: String) -> String {
    let today = Date().convertdateToUTC().toDateString()
    let yesterday = Date().adding(value: -1, byAdding: .day).convertdateToUTC().toDateString()
    if createdDateTime == today {
      return Localize.string("common_today")
    }
    else if createdDateTime == yesterday {
      return Localize.string("common_yesterday")
    }
    else {
      return createdDateTime
    }
  }
}
