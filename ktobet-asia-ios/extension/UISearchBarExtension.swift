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
            let svs = subviews.flatMap { $0.subviews }
            guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return nil }
            return tf.textColor
        }
        set {
            let svs = subviews.flatMap { $0.subviews }
            guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
            tf.textColor = newValue
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
