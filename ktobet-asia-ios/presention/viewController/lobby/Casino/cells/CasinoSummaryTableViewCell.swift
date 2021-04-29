import UIKit
import share_bu

class CasinoSummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var recordCountLabel: UILabel!
    @IBOutlet weak var betAmountLabel: UILabel!
    
    private let today = Date().convertdateToUTC().formatDateToStringToDay(with: "-")
    private let yesterday = Date().adding(value: -1, byAdding: .day).convertdateToUTC().formatDateToStringToDay(with: "-")

    func setup(element: DateSummary) {
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        if "\(element.createdDateTime)" == today {
            dateLabel.text = Localize.string("common_today")
        } else if "\(element.createdDateTime)" == yesterday {
            dateLabel.text = Localize.string("common_yesterday")
        } else {
            dateLabel.text = "\(element.createdDateTime)".replacingOccurrences(of: "-", with: "/")
        }
        
        let status = element.getBetStatus() == BetStatus.lose ? Localize.string("common_lose") : Localize.string("common_win")
        betAmountLabel.text = String(format: Localize.string("product_total_bet"), element.totalStakes.amount.currencyFormatWithoutSymbol(precision: 2)) + "  " + status + " \(abs(element.totalWinLoss.amount).currencyFormatWithoutSymbol(precision: 2))"
    }
}
