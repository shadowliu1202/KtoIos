import RxSwift
import SharedBu
import UIKit

class SBKMaintenanceViewController: MaintenanceViewController {
  let max_display_days = 99
  @IBOutlet var dayLabel: UILabel!
  @IBOutlet var hourLabel: UILabel!
  @IBOutlet var minuteLabel: UILabel!
  @IBOutlet var secondLabel: UILabel!
  @IBOutlet var imageView: UIImageView!

  private var localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!

  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = Theme.shared.getUIImage(name: "maintainSBK", by: localStorageRepo.getSupportLocale())
  }

  override func setTextPerSecond(_ countdownseconds: Int) {
    var remainder = countdownseconds
    let days = remainder / 86400
    remainder -= days * 86400
    let hours = remainder / 3600
    remainder -= hours * 3600
    let minutes = remainder / 60
    remainder -= minutes * 60
    let seconds = remainder
    dayLabel.text = days < max_display_days ? String(format: "%02d", days) : "\(max_display_days)"
    hourLabel.text = String(format: "%02d", hours)
    minuteLabel.text = String(format: "%02d", minutes)
    secondLabel.text = String(format: "%02d", seconds)
  }
}
