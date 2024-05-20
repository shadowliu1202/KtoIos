import UIKit

class FakeNavigationController: UINavigationController {
    var lastNavigatedViewController: UIViewController?

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        lastNavigatedViewController = viewController
        super.pushViewController(viewController, animated: animated)
    }
  
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        lastNavigatedViewController = viewControllerToPresent
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
