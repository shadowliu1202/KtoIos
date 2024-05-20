import RxCocoa
import RxSwift
import UIKit

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }

    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

extension UITextField {
    func remainCursor(to new: String) {
        guard let selectedTextRange else { return }

        let currentCursorPosition = offset(from: beginningOfDocument, to: selectedTextRange.start)
        let selectedCount = offset(from: selectedTextRange.start, to: selectedTextRange.end)
        let differentCount = new.count - (text?.count ?? 0)

        let cursorOffset = currentCursorPosition + selectedCount + differentCount

        text = new

        if let newCursorPosition = position(from: beginningOfDocument, offset: cursorOffset) {
            DispatchQueue.main.async {
                self.selectedTextRange = self.textRange(from: newCursorPosition, to: newCursorPosition)
            }
        }
    }
}

extension UITextField {
    // FIXME: workaround iOS16 textfield autofill feature will cause crash.
    // https://developer.apple.com/forums/thread/714608
    // Use oneTimeCode of textContentType to disable autofill.
    // https://developer.apple.com/forums/thread/108085
    func disableAutoFillOnIos16() {
        if #available(iOS 16.0, *) {
            self.textContentType = .oneTimeCode
        }
    }
}

/// For overwrite UITextField  return text value  to 半形
extension Reactive where Base: UITextField {
    /// Reactive wrapper for `text` property.
    public var text: ControlProperty<String?> {
        base.rx.controlProperty(editingEvents: [.allEditingEvents, .valueChanged]) { textField in
            textField.text?.halfWidth
        } setter: { textField, value in
            if textField.text != value {
                textField.text = value
            }
        }
    }
}
