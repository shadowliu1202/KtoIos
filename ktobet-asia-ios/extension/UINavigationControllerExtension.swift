import UIKit

extension UINavigationController {
  override open func viewDidLoad() {
    super.viewDidLoad()
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    navigationBar.shadowImage = UIImage()
  }
}
