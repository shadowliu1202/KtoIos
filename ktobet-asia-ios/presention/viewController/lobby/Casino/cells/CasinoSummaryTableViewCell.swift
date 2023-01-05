import UIKit
import SharedBu

class CasinoSummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recordCountLabel: UILabel!
    @IBOutlet weak var betAmountLabel: UILabel!
    
    func setup(element: DateSummary) {
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        dateLabel.text = element.createdDateTime.toBetDisplayDate()
        let status = element.totalWinLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
        betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.totalStakes.description()) + "  " + status + " \(element.totalWinLoss.formatString(.none))"
    }
    
    func setup(element: NumberGameSummary.Date) {
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        dateLabel.text = element.betDate.toBetDisplayDate()
        
        if let winLoss = element.winLoss {
            let status = winLoss.isPositive ? Localize.string("common_win") : Localize.string("common_lose")
            betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.stakes.description()) + "  " + status + " \(winLoss.formatString(.none))"
        } else {
            betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.stakes.description())
        }
    }
}
