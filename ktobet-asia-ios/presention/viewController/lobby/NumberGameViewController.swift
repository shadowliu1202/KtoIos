import UIKit

class NumberGameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    }
}
