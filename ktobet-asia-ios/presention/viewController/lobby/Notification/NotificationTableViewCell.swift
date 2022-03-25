import UIKit
import SharedBu

class NotificationTableViewCell: UITableViewCell {
    @IBOutlet weak var typeTitle: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var maintainTime: UILabel!

    private var previousKeyword: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        self.title.highlight(text: previousKeyword, color: .clear)
        self.content.highlight(text: previousKeyword, color: .clear)
    }

    func setUp(_ element: SharedBu.Notification, supportLocale: SupportLocale, keyword: String = "") {
        self.previousKeyword = keyword
        typeTitle.text = createTypeTitle(element)
        date.text = element.displayTime.toDateTimeString()

        title.text = NotificationViewModel.createActivityTitle(notification: element)
        content.text = NotificationViewModel.createActivityContent(notification: element, supportLocale: supportLocale)
       

        if let maintainNotification = element as? SharedBu.Notification.Maintenance {
            let maintenanceStart = maintainNotification.maintenanceStart.toDateString()
            let maintenanceEnd = maintainNotification.maintenanceEnd.toDateString()
            maintainTime.text = Localize.string("notification_maintenancetime",
                                                maintainNotification.maintenanceStart.toDateTimeString(),
                                                maintenanceStart == maintenanceEnd ? maintainNotification.maintenanceEnd.toTimeString() : maintainNotification.maintenanceEnd.toDateTimeString())

        } else {
            maintainTime.text = ""
        }

        self.title.highlight(text: keyword.trimmingCharacters(in: .whitespacesAndNewlines), color: .redForDark502)
        self.content.highlight(text: keyword.trimmingCharacters(in: .whitespacesAndNewlines), color: .redForDark502)
    }

    private func createTypeTitle(_ element: SharedBu.Notification) -> String {
        switch element {
        case is SharedBu.Notification.Maintenance:
            return Localize.string("notification_type_0")
        case is SharedBu.Notification.Activity:
            return Localize.string("notification_type_activity")
        case is SharedBu.Notification.General:
            return Localize.string("notification_type_1")
        case is SharedBu.Notification.Personal:
            return Localize.string("notification_type_2")
        default:
            return ""
        }
    }
}
