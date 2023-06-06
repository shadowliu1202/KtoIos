import RxSwift
import UIKit

protocol EmbedNavigation { }

extension EmbedNavigation where Self: UIViewController {
  func setBackItem(
    _ barItemType: BarItemType,
    action: (() -> Void)? = nil)
    -> Disposable
  {
    let button = UIBarButtonItem()
    button.style = .plain

    var _action: (() -> Void)? = action

    switch barItemType {
    case .back:
      button.image = UIImage(named: "Back")?.withRenderingMode(.alwaysOriginal)
      _action = { [weak self] in
        self?.navigationController?.popViewController(animated: true)
      }

    case .close:
      button.image = UIImage(named: "Close")?.withRenderingMode(.alwaysOriginal)
      _action = { [weak self] in
        self?.dismiss(animated: true)
      }

    case .none:
      break
    }

    navigationItem.leftBarButtonItem = button

    return button.rx
      .tap
      .subscribe(onNext: { _action?() })
  }

  func embedToNavigation() -> UINavigationController {
    let navigation = UINavigationController(rootViewController: self)
    navigation.modalPresentationStyle = .fullScreen
    return navigation
  }
}
