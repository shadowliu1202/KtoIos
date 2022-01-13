import UIKit

class AccountNotifyViewController: APPViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: nil)
    }
}
