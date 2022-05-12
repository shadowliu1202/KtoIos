import UIKit
import SDWebImage

extension UIImageView {
    func sd_setImage(url: URL?, placeholderImage: UIImage? = nil, context: [SDWebImageContextOption : Any]? = nil) {
        var sdWebImageOptions: SDWebImageOptions = [.refreshCached]
        if Configuration.disableSSL {
            sdWebImageOptions.insert(.allowInvalidSSLCertificates)
        }
        self.sd_setImage(with: url, placeholderImage: placeholderImage, options: sdWebImageOptions, context: context)
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

