import RxSwift
import sharedbu
import UIKit

class ProductMaintenanceViewController: MaintenanceViewController {
  let max_display_hour = 999
  @IBOutlet var hourLabel: UILabel!
  @IBOutlet var minuteLabel: UILabel!
  @IBOutlet var secondLabel: UILabel!
  @IBOutlet var textView: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()
    initTextViewAttr()
  }

  func initTextViewAttr() {
    textView.textContainerInset = .zero
    let suffix = Localize.string("common_kto")
    let maintenance = Localize.string("common_maintenance_description")
    let attributedText = NSAttributedString(text: maintenance)
      .color(.textPrimary)
      .font(UIFont(name: "PingFangSC-Semibold", size: 24)!)
      .color(.primaryDefault, for: suffix)
      .alignment(.center)
    textView.attributedText = attributedText
  }

  override func setTextPerSecond(_ countdownseconds: Int) {
    var remainder = countdownseconds
    let hours = remainder / 3600
    remainder -= hours * 3600
    let minutes = remainder / 60
    remainder -= minutes * 60
    let seconds = remainder
    hourLabel.text = hours < max_display_hour ? String(format: "%02d", hours) : "\(max_display_hour)"
    minuteLabel.text = String(format: "%02d", minutes)
    secondLabel.text = String(format: "%02d", seconds)
  }
}
