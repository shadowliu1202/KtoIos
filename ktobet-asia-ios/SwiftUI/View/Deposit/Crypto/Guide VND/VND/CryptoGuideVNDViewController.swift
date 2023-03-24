import SwiftUI
import UIKit

class CryptoGuideVNDViewController:
  LobbyViewController,
  SwiftUIConverter
{
  private let viewModel = Injectable.resolve(CryptoGuideVNDViewModelImpl.self)!

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    addSubView(CryptoGuideVNDView(viewModel: self.viewModel), to: view)
  }
}
