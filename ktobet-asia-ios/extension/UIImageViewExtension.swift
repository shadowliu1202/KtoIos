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
}

