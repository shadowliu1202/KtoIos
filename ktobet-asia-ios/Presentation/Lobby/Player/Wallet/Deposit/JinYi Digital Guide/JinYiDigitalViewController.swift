import sharedbu
import SwiftUI
import UIKit

class JinYiDigitalViewController: LobbyViewController {
  @Injected var playerConfiguration: PlayerConfiguration

  override func viewDidLoad() {
    super.viewDidLoad()

    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    addSubView(
      JinYiDigitalGuideView(locale: playerConfiguration.supportLocale),
      to: view)
  }
}
