import UIKit

extension UISearchBar {
    @IBInspectable
    public var localizePlaceholder: String? {
        get { return placeholder }
        set { placeholder = newValue == nil ? nil : Localize.string(newValue!) }
    }
    
    @IBInspectable
    public var textColor: UIColor? {
        get {
            return self.textField?.textColor
        }
        set {
            self.textField?.textColor = newValue
        }
    }
    
    func addDoneButton(title: String, target: Any, selector: Selector) {
        let toolbar = UIToolbar(frame: CGRect(x: .zero,
                                              y: .zero,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButton = UIBarButtonItem(title: title, style: .plain, target: target, action: selector)
        toolbar.setItems([flexible, barButton], animated: false)
        inputAccessoryView = toolbar
    }
    
    var textField : UITextField? {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            let svs = subviews.flatMap { $0.subviews }
            return (svs.filter { $0 is UITextField }).first as? UITextField
        }
    }
    
    func removeMagnifyingGlass() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: self.frame.size.height))
        self.textField?.leftView = paddingView
        self.textField?.leftViewMode = .always
    }
    
    func setCursorColorTo(color: UIColor) {
        self.textField?.tintColor = color
    }
    
    func setMagnifyingGlassColorTo(color: UIColor) {
        // Search Icon
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        let glassIconView = textFieldInsideSearchBar?.leftView as? UIImageView
        glassIconView?.image = glassIconView?.image?.withRenderingMode(.alwaysTemplate)
        glassIconView?.tintColor = color
    }
    
    func setClearButtonColorTo(color: UIColor) {
        // Clear Button
        let textFieldInsideSearchBar = self.value(forKey: "searchField") as? UITextField
        let crossIconView = textFieldInsideSearchBar?.value(forKey: "clearButton") as? UIButton
        crossIconView?.setImage(UIImage(named: "Close"), for: .normal)
        crossIconView?.tintColor = color
    }
}
