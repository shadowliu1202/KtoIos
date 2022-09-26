import UIKit
import SwiftUI

class CryptoGuideVNDViewController: LobbyViewController {
    static let segueIdentifier = "toCryptoVNDGuide"
    
    private let viewModel = DI.resolve(CryptoGuideVNDViewModelImpl.self)!

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    }
    
    @IBSegueAction func toCryptoGuideVNDView(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: CryptoGuideVNDView(viewModel: viewModel))
    }

}
