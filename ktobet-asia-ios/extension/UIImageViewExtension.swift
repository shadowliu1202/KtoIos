import UIKit
import SDWebImage

extension UIImageView {
    func sd_setImage(url: URL?, placeholderImage: UIImage? = nil, context: [SDWebImageContextOption : Any]? = nil) {
        self.sd_setImage(with: url, placeholderImage: placeholderImage, options: Configuration.disableSSL ? .allowInvalidSSLCertificates : SDWebImageOptions.init(), context: context)
    }
}

