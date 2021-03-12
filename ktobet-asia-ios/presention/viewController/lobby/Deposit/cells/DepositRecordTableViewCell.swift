import UIKit
import share_bu

class DepositRecordTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    
    func setUp(data: DepositRecord) {
        dateLabel.text = data.createdDate.formatDateToStringToSecond()
        idLabel.text = data.isFee ? String(format: Localize.string("common_depositfeerefund"), data.displayId) : data.displayId
        statusLabel.text = StringMapper.sharedInstance.parse(data.transactionStatus, isPendingHold: data.isPendingHold)
        statusLabel.textColor = ColorMapper.sharedInstance.parse(data.transactionStatus)
        amountLabel.text = String(data.requestAmount.amount)
    }
}
