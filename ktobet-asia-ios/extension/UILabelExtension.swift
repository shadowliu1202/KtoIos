import UIKit

extension UILabel {
    
    @IBInspectable
    public var localizeText: String? {
        get { return text }
        set { text = newValue == nil ? nil : Localize.string(newValue!) }
    }
}
