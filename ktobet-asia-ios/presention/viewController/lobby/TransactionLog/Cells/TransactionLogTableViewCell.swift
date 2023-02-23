import SharedBu
import UIKit

class TransactionLogTableViewCell: UITableViewCell {
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!

  static let identifier = "TransactionLogTableViewCell"

  func setUp(data: TransactionLog) {
    dateLabel.text = data.date.toTimeString()
    nameLabel.text = data.name
    amountLabel.text = data.amount.formatString(sign: .signed_)
    amountLabel.textColor = data.amount.isPositive ? UIColor.green6AB336 : UIColor.gray9B9B9B
  }
}
