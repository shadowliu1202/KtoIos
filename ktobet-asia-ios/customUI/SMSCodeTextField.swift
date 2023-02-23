import Foundation
import UIKit

protocol SMSCodeTextFieldDelegate: AnyObject {
  func textFieldDidDelete(_ sender: SMSCodeTextField)
}

class SMSCodeTextField: UITextField {
  weak var myDelegate: SMSCodeTextFieldDelegate?
  private var emptyCount = 0

  override func deleteBackward() {
    super.deleteBackward()
    myDelegate?.textFieldDidDelete(self)
  }
}
