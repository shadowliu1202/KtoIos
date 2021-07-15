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
        
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        dateLabel.text = displayDate(element.createdDateTime)
        let status = element.totalWinLoss >= 0 ? Localize.string("common_win") : Localize.string("common_lose")
        betAmountLabel.text = String(format: Localize.string("product_total_bet"), displayAmount(element.totalStakes)) + "  " + status + " \(displayAmount(element.totalWinLoss))"
        
        return self
    }
    
    private func displayDate(_ createdDateTime: String) -> String {
        let today = Date().convertdateToUTC().formatDateToStringToDay()
        let yesterday = Date().adding(value: -1, byAdding: .day).convertdateToUTC().formatDateToStringToDay()
        if createdDateTime == today {
            return Localize.string("common_today")
        } else if createdDateTime == yesterday {
            return Localize.string("common_yesterday")
        } else {
            return createdDateTime
        }
    }
    
    private func displayAmount(_ amount: Double) -> String {
        if amount >= 0 {
            return amount.currencyFormatWithoutSymbol(precision: 2)
        } else {
            return abs(amount).currencyFormatWithoutSymbol(precision: 2)
        }
    }
    
}
