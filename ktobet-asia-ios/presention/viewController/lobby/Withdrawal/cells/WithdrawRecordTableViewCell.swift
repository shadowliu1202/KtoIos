import UIKit
import SharedBu

class WithdrawRecordTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    
    func setUp(data: WithdrawalRecord) {
        dateLabel.text = data.createDate.toDateTimeString()
        idLabel.text = data.displayId
        statusLabel.text = StringMapper.sharedInstance.parse(data.transactionStatus, isPendingHold: data.isPendingHold, ignorePendingHold: false)
        statusLabel.textColor = ColorMapper.sharedInstance.parse(data.transactionStatus)
        amountLabel.text = data.cashAmount.displayAmount
    }
}
