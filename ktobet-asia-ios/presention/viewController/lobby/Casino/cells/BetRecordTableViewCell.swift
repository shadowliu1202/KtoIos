import UIKit
import SharedBu


class BetRecordTableViewCell: UITableViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var totalAmountLabel: UILabel!
    @IBOutlet private weak var winAmountLabel: UILabel!
    @IBOutlet private weak var goIconImageView: UIImageView!
    
    func setupUnSettleGame(_ name: String, betId: String, totalAmount: Double) {
        nameLabel.text = name
        orderIdLabel.text = betId
        totalAmountLabel.text = String(format: Localize.string("product_total_bet"), totalAmount.currencyFormatWithoutSymbol(precision: 2, roundingMode: .down))
    }
    
    func setup(name: String, betId: String, totalAmount: Double, winAmount: Double, betStatus: BetStatus, hasDetail: Bool, prededuct: Double) {
        goIconImageView.isHidden = !hasDetail
        nameLabel.text = name
        orderIdLabel.text = betId
        totalAmountLabel.text = String(format: Localize.string("product_total_bet"), totalAmount.currencyFormatWithoutSymbol(precision: 2, roundingMode: .down)) + (prededuct != 0 ? " \(Localize.string("product_prededuct")) " + prededuct.currencyFormatWithoutSymbol(precision: 2, roundingMode: .down) : "")
        winAmountLabel.text = (betStatus == BetStatus.lose ? Localize.string("common_lose") : Localize.string("common_win")) + " \(abs(winAmount).currencyFormatWithoutSymbol(precision: 2, roundingMode: .down))"
    }
}
