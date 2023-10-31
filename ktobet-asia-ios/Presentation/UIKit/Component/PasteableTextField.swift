import UIKit

class PasteableTextField: UITextField {
  @IBInspectable public var disablePaste = false
  
  override var undoManager: UndoManager? { nil }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(UIResponderStandardEditActions.paste(_:)) {
      return !disablePaste
    }

    if #available(iOS 15.0, *) {
      if action == #selector(UIResponder.captureTextFromCamera(_:)) {
        return !disablePaste
      }
    }

    return super.canPerformAction(action, withSender: sender)
  }
}
