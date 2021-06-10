import UIKit
import SharedBu

class CasinoSummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recordCountLabel: UILabel!
    @IBOutlet weak var betAmountLabel: UILabel!
    
    private let today = Date().convertdateToUTC().formatDateToStringToDay(with: "-")
    private let yesterday = Date().adding(value: -1, byAdding: .day).convertdateToUTC().formatDateToStringToDay(with: "-")

    func setup(element: DateSummary) {
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        dateLabel.text = element.createdDateTime.toBetDisplayDate()
        
        let status = element.getBetStatus() == BetStatus.lose ? Localize.string("common_lose") : Localize.string("common_win")
        betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.totalStakes.amount.currencyFormatWithoutSymbol(precision: 2, roundingMode: .down)) + "  " + status + " \(abs(element.totalWinLoss.amount).currencyFormatWithoutSymbol(precision: 2, roundingMode: .down))"
    }
    
    func setup(element: NumberGameSummary.Date) {
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        dateLabel.text = element.betDate.toBetDisplayDate()
        
        if let winLoss = element.winLoss, winLoss.amount != 0 {
            let status = winLoss.amount < 0 ? Localize.string("common_lose") : Localize.string("common_win")
            betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.stakes.amount.currencyFormatWithoutSymbol(precision: 2, roundingMode: .down)) + "  " + status + " \(abs(winLoss.amount).currencyFormatWithoutSymbol(precision: 2, roundingMode: .down))"
        } else {
            betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.stakes.amount.currencyFormatWithoutSymbol(precision: 2, roundingMode: .down))
        }
    }
}
