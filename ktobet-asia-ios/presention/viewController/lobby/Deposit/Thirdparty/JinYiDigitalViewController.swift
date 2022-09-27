import UIKit
import SwiftUI

class JinYiDigitalViewController: LobbyViewController {
    static let segueIdentifier = "toJinYiDigitalUserGuideSegue"

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    }
    
    @IBSegueAction func toJinYiDigitalGuide(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: JinYiDigitalGuideView())
    }
}
