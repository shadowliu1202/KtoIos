import UIKit

class NavigationControllerMock: UINavigationController {
  var pushedViewControllerType: UIViewController.Type?

  override init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    super.pushViewController(viewController, animated: animated)
    self.pushedViewControllerType = type(of: viewController)
  }
}
