import UIKit
import RxSwift

class SBKViewController: UIViewController {
    @IBOutlet weak var button: UIButton!

    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    }
}
