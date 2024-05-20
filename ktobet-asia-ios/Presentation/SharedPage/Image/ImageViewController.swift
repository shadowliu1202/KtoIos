import SDWebImage
import sharedbu
import UIKit

class ImageViewController: UIViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    static let segueIdentifier = "toShowBigImageSegue"
    @IBOutlet private weak var imageView: UIImageView!

    var url: String!
    var thumbnailImage: UIImage?
    var currentTransform: CGAffineTransform?
    let maxScale: CGFloat = 4.0
    let minScale: CGFloat = 1.0

    static func instantiate(
        url: String,
        thumbnailImage: UIImage? = nil)
        -> ImageViewController
    {
        let controller = ImageViewController.initFrom(storyboard: "Deposit")
        controller.url = url
        controller.thumbnailImage = thumbnailImage
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))

        self.imageView.sd_setImage(url: URL(string: url), placeholderImage: thumbnailImage)
        self.imageView.enableZoom()
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapAction))
        doubleTapGesture.numberOfTapsRequired = 2
        self.imageView.addGestureRecognizer(doubleTapGesture)
    }

    @objc
    func close() {
        NavigationManagement.sharedInstance.popViewController(nil)
    }

    @objc
    func doubleTapAction(gesture: UITapGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.ended {
            // Store current transfrom of UIImageView
            currentTransform = self.imageView.transform
            var doubleTapStartCenter = self.imageView.center

            var transform: CGAffineTransform!
            var scale: CGFloat = 2.0 // x2 double tapped

            // Get current scale
            let currentScale =
                sqrt(abs(
                    self.imageView.transform.a * self.imageView.transform.d - self.imageView.transform.b * self.imageView
                        .transform.c))

            // Get tapped location
            let tappedLocation = gesture.location(in: self.imageView)

            var newCenter: CGPoint
            if self.maxScale < currentScale * scale { // Upper higher scale limit
                scale = self.minScale
                transform = CGAffineTransform.identity

                newCenter = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2)
                doubleTapStartCenter = newCenter
            }
            else {
                transform = self.currentTransform!.concatenating(CGAffineTransform(scaleX: scale, y: scale))

                newCenter = CGPoint(
                    x: doubleTapStartCenter
                        .x - ((tappedLocation.x - doubleTapStartCenter.x) * scale - (tappedLocation.x - doubleTapStartCenter.x)),
                    y: doubleTapStartCenter
                        .y - ((tappedLocation.y - doubleTapStartCenter.y) * scale - (tappedLocation.y - doubleTapStartCenter.y)))
            }

            // Update view
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: { () in
                self.imageView.center = newCenter
                self.imageView.transform = transform

            }, completion: { (_: Bool) in
            })
        }
    }
}
