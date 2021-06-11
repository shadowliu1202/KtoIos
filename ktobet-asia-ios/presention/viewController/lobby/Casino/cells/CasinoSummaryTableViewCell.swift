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
        betAmountLabel.text = CashAmount.productTotalBet(betAmount: element.totalStakes, winLoss: element.totalWinLoss)
    }
    
    func setup(element: NumberGameSummary.Date) {
        recordCountLabel.text = String(format: Localize.string("product_count_bet_record"), "\(element.count.formattedWithSeparator)")
        dateLabel.text = element.betDate.toBetDisplayDate()
        betAmountLabel.text = CashAmount.productTotalBet(betAmount: element.stakes, winLoss: element.winLoss)
    }
}
