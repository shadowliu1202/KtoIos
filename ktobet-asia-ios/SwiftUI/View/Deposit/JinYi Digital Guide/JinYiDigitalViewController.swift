import SwiftUI
import UIKit

class JinYiDigitalViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected var localRepo: LocalStorageRepository

  override func viewDidLoad() {
    super.viewDidLoad()

    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    addSubView(
      JinYiDigitalGuideView(locale: localRepo.getSupportLocale()),
      to: view)
  }
}
