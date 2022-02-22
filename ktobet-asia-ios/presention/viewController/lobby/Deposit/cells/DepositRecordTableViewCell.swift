import UIKit
import SharedBu

class DepositRecordTableViewCell: UITableViewCell {
    enum DisplayDate {
        case dateTime
        case date
        case time
    }
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    
    func setUp(data: DepositRecord, isOnlyTimeFormat: Bool = false) {
        dateLabel.text = isOnlyTimeFormat ? data.createdDate.toTimeString() : data.createdDate.toDateTimeString()
        idLabel.text = data.isFee ? String(format: Localize.string("common_depositfeerefund"), data.displayId) : data.displayId
        statusLabel.text = StringMapper.sharedInstance.parse(data.transactionStatus, isPendingHold: data.isPendingHold, ignorePendingHold: true)
        statusLabel.textColor = ColorMapper.sharedInstance.parse(data.transactionStatus)
        amountLabel.text = data.calculateDepositAmount().formatString()
    }
    
    func setup(_ item: PaymentLogDTO.Log, displayFormat: DisplayDate) {
        var dateStr = ""
        switch displayFormat {
        case .dateTime:
            dateStr = item.createdDate.toDateTimeString()
        case .date:
            dateStr = item.createdDate.toDateString()
            break
        case .time:
            dateStr = item.createdDate.toTimeString()
            break
        }
        dateLabel.text = dateStr
        idLabel.text = item.displayId
        statusLabel.text = item.status.toLogString()
        statusLabel.textColor = item.status.toLogColor()
        amountLabel.text = item.amount.formatString()
    }
}
