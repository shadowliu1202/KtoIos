import Foundation
import UIKit

protocol SMSCodeTextFieldDelegate: AnyObject {
  func textFieldDidDelete(_ sender: SMSCodeTextField)
}

class SMSCodeTextField: UITextField {
  weak var myDelegate: SMSCodeTextFieldDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    delegate = self
    initUI()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    delegate = self
    initUI()
  }
  
  override func deleteBackward() {
    super.deleteBackward()
    myDelegate?.textFieldDidDelete(self)
  }
  
  private func initUI() {
    textContentType = .oneTimeCode
    keyboardType = .numberPad
    textAlignment = .center
    textColor = .white
    tintColor = .clear
    backgroundColor = .inputDefault
    layer.cornerRadius = 6
    cornerRadius = 6
    layer.masksToBounds = true
    font = UIFont(name: "PingFangSC-Semibold", size: 18)
    
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: 40).isActive = true
    heightAnchor.constraint(equalToConstant: 40).isActive = true
  }
}

extension SMSCodeTextField: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    textField.backgroundColor = .inputFocus
    return true
  }
  
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    textField.backgroundColor = .inputDefault
    return true
  }
  
  func textFieldDidBeginEditing(_ textField: UITextField) {
    let newPosition = textField.endOfDocument
    DispatchQueue.main.async {
      textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
    }
  }
}
