import UIKit
import SharedBu


class BetRecordTableViewCell: UITableViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var totalAmountLabel: UILabel!
    @IBOutlet private weak var winAmountLabel: UILabel!
    @IBOutlet private weak var goIconImageView: UIImageView!
    
    func setupUnSettleGame(_ name: String, betId: String, totalAmount: CashAmount) {
        nameLabel.text = name
        orderIdLabel.text = betId
        totalAmountLabel.text = String(format: Localize.string("product_total_bet"), totalAmount.description())
    }
    
    func setup(name: String, betId: String, totalAmount: CashAmount, winAmount: CashAmount, betStatus: BetStatus, hasDetail: Bool, prededuct: CashAmount) {
        goIconImageView.isHidden = !hasDetail
        nameLabel.text = name
        orderIdLabel.text = betId
        totalAmountLabel.text = String(format: Localize.string("product_total_bet"), totalAmount.description()) + (prededuct.amount != 0 ? " \(Localize.string("product_prededuct")) " + prededuct.description() : "")
        winAmountLabel.text = (betStatus == BetStatus.lose ? Localize.string("common_lose") : Localize.string("common_win")) + " \(winAmount.formatString())"
    }
}
