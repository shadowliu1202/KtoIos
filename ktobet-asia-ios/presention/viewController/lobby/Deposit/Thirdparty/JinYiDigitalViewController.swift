import SwiftUI
import UIKit

class JinYiDigitalViewController: LobbyViewController {
  static let segueIdentifier = "toJinYiDigitalUserGuideSegue"

  @Injected var localRepo: LocalStorageRepository

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
  }

  @IBSegueAction
  func toJinYiDigitalGuide(_ coder: NSCoder) -> UIViewController? {
    UIHostingController(coder: coder, rootView: JinYiDigitalGuideView(locale: localRepo.getSupportLocale()))
  }
}
