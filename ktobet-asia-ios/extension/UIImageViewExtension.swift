import UIKit
import SDWebImage

extension UIImageView {
    func sd_setImage(url: URL?, placeholderImage: UIImage? = nil, context: [SDWebImageContextOption : Any]? = nil, completed: SDExternalCompletionBlock? = nil) {
        self.sd_setImage(with: url, placeholderImage: placeholderImage, options: [.refreshCached], context: context, progress: nil, completed: completed)
    }
    
    @IBInspectable
    public var setTintColor: UIColor {
        get { return self.tintColor }
        set {
            let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
            self.image = templateImage
            self.tintColor = newValue
        }
    }
}

