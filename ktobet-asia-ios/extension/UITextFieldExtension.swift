import UIKit
import RxSwift
import RxCocoa

extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat){
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

/// For overwrite UITextField  return text value  to 半形
extension Reactive where Base: UITextField {
    /// Reactive wrapper for `text` property.
    public var text: ControlProperty<String?> {
        return base.rx.controlProperty(editingEvents: [.allEditingEvents, .valueChanged]) { textField in
            textField.text?.halfWidth
        } setter: { textField, value in
            if textField.text != value {
                textField.text = value
            }
        }
    }
}
