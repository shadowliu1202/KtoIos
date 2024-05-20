import SDWebImage
import UIKit

extension UIImageView {
    func sd_setImage(
        url: URL?,
        placeholderImage: UIImage? = nil,
        context: [SDWebImageContextOption: Any]? = nil,
        completed: SDExternalCompletionBlock? = nil)
    {
        sd_setImage(
            with: url,
            placeholderImage: placeholderImage,
            options: [.refreshCached, .handleCookies],
            context: context,
            progress: nil,
            completed: completed)
    }

    @IBInspectable public var setTintColor: UIColor {
        get { self.tintColor }
        set {
            let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
            self.image = templateImage
            self.tintColor = newValue
        }
    }
  
    func enableZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:)))
        isUserInteractionEnabled = true
        addGestureRecognizer(pinchGesture)
    }
  
    @objc
    private func startZooming(_ sender: UIPinchGestureRecognizer) {
        let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
        guard let scale = scaleResult, scale.a > 1, scale.d > 1 else { return }
        sender.view?.transform = scale
        sender.scale = 1
    }
}
