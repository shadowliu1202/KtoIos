import UIKit

extension UITextView {
    @IBInspectable public var localizeText: String? {
        get { text }
        set { text = newValue == nil ? nil : Localize.string(newValue!) }
    }
  
    func setLinkColor(_ color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: color,
            .underlineColor: color
        ]
    
        self.linkTextAttributes = attributes
    }
}
