import UIKit

class LegalSupervisionViewController: UIViewController {
    static let segueIdentifier = "toLegalSupervision"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
