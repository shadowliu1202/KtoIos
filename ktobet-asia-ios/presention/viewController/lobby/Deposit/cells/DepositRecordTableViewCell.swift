import UIKit
import SharedBu

class DepositRecordTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    
    func setUp(data: DepositRecord, isOnlyTimeFormat: Bool = false) {
        dateLabel.text = isOnlyTimeFormat ? data.createdDate.toTimeString() : data.createdDate.toDateTimeString()
        idLabel.text = data.isFee ? String(format: Localize.string("common_depositfeerefund"), data.displayId) : data.displayId
        statusLabel.text = StringMapper.sharedInstance.parse(data.transactionStatus, isPendingHold: data.isPendingHold, ignorePendingHold: true)
        statusLabel.textColor = ColorMapper.sharedInstance.parse(data.transactionStatus)
        amountLabel.text = data.requestAmount.description()
    }
}
