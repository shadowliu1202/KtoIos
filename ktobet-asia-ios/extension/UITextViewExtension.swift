import UIKit

extension UITextView {
  @IBInspectable  public var localizeText: String? {
    get { text }
    set { text = newValue == nil ? nil : Localize.string(newValue!) }
  }
}
