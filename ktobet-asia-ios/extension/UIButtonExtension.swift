import Foundation
import RxCocoa
import RxSwift
import UIKit

extension UIButton {
  @IBInspectable  public var localizeTitle: String? {
    get { title(for: .normal) }
    set { setTitle(newValue == nil ? nil : Localize.string(newValue!), for: .normal) }
  }

  var isValid: Bool {
    get {
      self.isEnabled
    }
    set {
      self.isEnabled = newValue
      self.alpha = newValue ? 1 : 0.3
      self.titleLabel?.alpha = newValue ? 1 : 0.9
    }
  }

  public var allImage: UIImage? {
    get { image(for: .normal) }
    set {
      setImage(newValue, for: .normal)
      setImage(newValue, for: .selected)
      setImage(newValue, for: .highlighted)
      setImage(newValue, for: .disabled)
      setImage(newValue, for: .focused)
      setImage(newValue, for: .reserved)
    }
  }
}

extension UIButton {
  private func imageWithColor(color: UIColor) -> UIImage {
    let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    UIGraphicsBeginImageContext(rect.size)
    guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }

    context.setFillColor(color.cgColor)
    context.fill(rect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image ?? UIImage()
  }

  func setBackgroundColor(color: UIColor, forUIControlState state: UIControl.State) {
    self.setBackgroundImage(imageWithColor(color: color), for: state)
  }
}

extension Reactive where Base: UIButton {
  public var touchUpInside: ControlEvent<Void> {
    self.controlEvent(.touchUpInside)
  }

  public var isValid: Binder<Bool> {
    Binder<Bool>(base, binding: { button, enable in
      button.isValid = enable
    })
  }
}
