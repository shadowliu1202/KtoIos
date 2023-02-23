import Photos
import UIKit

class CollectionViewCell: UICollectionViewCell {
  @IBOutlet weak var imgBackground: UIImageView!
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var cameraLabel: UILabel!
  @IBOutlet weak var cameraImageView: UIImageView!

  private var imageRequestID: PHImageRequestID?
  var indexPath: IndexPath?
  var photoAsset: PHAsset? {
    didSet {
      loadPhotoAssetIfNeeded()
    }
  }

  var size: CGSize? {
    didSet {
      loadPhotoAssetIfNeeded()
    }
  }

  private func loadPhotoAssetIfNeeded() {
    guard
      let indexPath = self.indexPath,
      let asset = photoAsset else { return }
    let manager = PHImageManager.default()
    let newSize = CGSize(width: 125, height: 125)
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    options.isSynchronous = false
    options.isNetworkAccessAllowed = true
    imageRequestID = manager.requestImage(
      for: asset,
      targetSize: newSize,
      contentMode: .aspectFill,
      options: options,
      resultHandler: { [weak self] result, _ in
        guard self?.indexPath?.item == indexPath.item else { return }
        self?.imageRequestID = nil
        self?.imgBackground.image = result
      })
  }
}
