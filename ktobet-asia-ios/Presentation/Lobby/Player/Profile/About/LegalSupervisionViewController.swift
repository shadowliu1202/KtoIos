import UIKit

class LegalSupervisionViewController: LobbyViewController {
  static let segueIdentifier = "toLegalSupervision"

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
  }

  override func networkDisconnectHandler() { }
}
