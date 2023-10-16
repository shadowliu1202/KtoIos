import sharedbu
import UIKit

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

  func setUp(_ element: NotificationItem, keyword: String = "") {
    self.previousKeyword = keyword
    typeTitle.text = element.typeTitle
    date.text = element.dateTime
    title.text = element.title
    content.text = element.content

    if let maintainStartTime = element.maintenanceTime, let maintainEndTime = element.maintenanceEndTime {
      let maintenanceStart = maintainStartTime.toDateString()
      let maintenanceEnd = maintainEndTime.toDateString()
      maintainTime.text = Localize.string(
        "notification_maintenancetime",
        maintainStartTime.toDateTimeString(),
        maintenanceStart == maintenanceEnd ?
          maintainEndTime.toTimeString() : maintainEndTime.toDateTimeString())
    }
    else {
      maintainTime.text = ""
    }

    self.title.highlight(
      text: keyword.trimmingCharacters(in: .whitespacesAndNewlines),
      color: .primaryDefault.withAlphaComponent(0.5))
    self.content.highlight(
      text: keyword.trimmingCharacters(in: .whitespacesAndNewlines),
      color: .primaryDefault.withAlphaComponent(0.5))
  }
}
