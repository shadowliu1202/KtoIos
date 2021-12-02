import UIKit

class AccountNotifyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: nil)
    }
}
