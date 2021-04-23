import UIKit
import  share_bu


class BetRecordTableViewCell: UITableViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var totalAmountLabel: UILabel!
    @IBOutlet private weak var winAmountLabel: UILabel!
    @IBOutlet private weak var goIconImageView: UIImageView!
    
    func setupUnSettleGame(_ name: String, betId: String, totalAmount: Double) {
        nameLabel.text = name
        orderIdLabel.text = betId
        totalAmountLabel.text = String(format: Localize.string("product_total_bet"), totalAmount.currencyFormatWithoutSymbol(precision: 2))
    }
    
    func setup(name: String, betId: String, totalAmount: Double, winAmount: Double, betStatus: BetStatus, hasDetail: Bool) {
        goIconImageView.isHidden = !hasDetail
        nameLabel.text = name
        orderIdLabel.text = betId
        totalAmountLabel.text = String(format: Localize.string("product_total_bet"), totalAmount.currencyFormatWithoutSymbol(precision: 2))
        winAmountLabel.text = (betStatus == BetStatus.win ? Localize.string("common_win") : Localize.string("common_lose")) + " \(abs(winAmount).currencyFormatWithoutSymbol(precision: 2))"
    }
}
