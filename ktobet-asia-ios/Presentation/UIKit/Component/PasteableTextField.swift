import SwiftUI
import UIKit

class PasteableTextField: UITextField {
  @IBInspectable public var disablePaste = false
  
  private lazy var textUndoManager = TextFieldUndoManager(textField: self)
  
  override var undoManager: UndoManager? { textUndoManager }
  
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
