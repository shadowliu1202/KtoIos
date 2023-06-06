import UIKit

public enum BarButtonPosition {
  case left
  case right
}

@objc
public protocol BarButtonItemable: AnyObject {
  var barButtonItems: [UIBarButtonItem] { get set }

  @objc
  optional func pressedRightBarButtonItems(_ sender: UIBarButtonItem)
  @objc
  optional func pressedLeftBarButtonItems(_ sender: UIBarButtonItem)
}

extension BarButtonItemable where Self: UIViewController {
  @discardableResult
  func bind(position: BarButtonPosition, barButtonItems: UIBarButtonItem?...) -> Self {
    self.bind(position: position, barButtonItems: barButtonItems.compactMap({ $0 }))
  }

  @discardableResult
  func bind(position: BarButtonPosition, barButtonItems: [UIBarButtonItem]?) -> Self {
    guard let barButtonItems else {
      navigationItem.hidesBackButton = true
      return self
    }

    let actionButtonItems = barButtonItems
      .compactMap { $0 }
      .map { [weak self] buttonItem -> UIBarButtonItem in
        guard let self else { return buttonItem }
        switch position {
        case .left:
          if !self.responds(to: #selector(self.pressedLeftBarButtonItems(_:))) { break }
          if buttonItem.target == nil {
            buttonItem.actionHandler({ [weak self] _ in
              self?.pressedLeftBarButtonItems?(buttonItem)
            })
          }
        case .right:
          if !self.responds(to: #selector(self.pressedRightBarButtonItems(_:))) { break }
          if buttonItem.target == nil {
            buttonItem.actionHandler({ [weak self] _ in
              self?.pressedRightBarButtonItems?(buttonItem)
            })
          }
        }
        return buttonItem
      }

    switch position {
    case .left: self.navigationItem.leftBarButtonItems = actionButtonItems
    case .right: self.navigationItem.rightBarButtonItems = actionButtonItems
    }
    actionButtonItems.forEach({
      self.barButtonItems.appendIfNotContains($0)
    })
    return self
  }
}
