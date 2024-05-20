import Foundation
import RxRelay
import UIKit

class SMSCodeTextField: UITextField {
    private let onInput: () -> Void
    private let onDelete: () -> Void
  
    init(
        onInput: @escaping (() -> Void) = { },
        onDelete: @escaping (() -> Void) = { })
    {
        self.onInput = onInput
        self.onDelete = onDelete
    
        super.init(frame: .init())
    
        delegate = self
        initUI()
    }
  
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override var undoManager: UndoManager? { nil }
  
    override func deleteBackward() {
        super.deleteBackward()
    
        changeText(to: "")
        onDelete()
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
  
    private func changeText(to newText: String) {
        text = newText
        sendActions(for: .editingChanged)
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
  
    func textField(_: UITextField, shouldChangeCharactersIn _: NSRange, replacementString string: String) -> Bool {
        if string.count == 1 {
            changeText(to: string)
            onInput()
        }
        else if string.isEmpty {
            changeText(to: string)
            onDelete()
        }
    
        return false
    }
}
