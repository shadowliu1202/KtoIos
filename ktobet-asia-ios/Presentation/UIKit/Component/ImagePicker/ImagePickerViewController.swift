import AVFoundation
import Photos
import UIKit

class ImagePickerViewController: UIViewController {
  @IBOutlet private weak var collectionView: UICollectionView!
  @IBOutlet private weak var countLabel: UILabel!
  @IBOutlet private weak var uploadButton: UIButton!
  @IBOutlet weak var footerView: UIView!

  @Injected private var loading: Loading
  
  private static let availableImageFormat = ["PNG", "JPG", "BMP", "JPEG"]
  
  weak var delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?
  var maxSelectedImageCount = Configuration.uploadImageCountLimit
  var cameraImage: UIImage?
  var cameraText: String?
  var isHiddenFooterView = false
  var cameraType: CameraType = .general
  var completion: ((_ assets: [UIImage]) -> Void)?
  var completionWithLocalIdentifier: ((_ identifier: [String]) -> Void)?
  var qrCodeCompletion: ((_ qrCodeString: String) -> Void)?
  var cancel: (() -> Void)?

  private var activityIndicator = UIActivityIndicatorView(style: .large)
  private var imageRequestID: PHImageRequestID?
  private var albums: [AlbumModel] = []
  private var photoAssets: PHFetchResult<PHAsset> = PHFetchResult()
  private var selectedAlbum: AlbumModel?
  private var selectedPhotoAssets: [PHAsset] = [] {
    didSet {
      if selectedPhotoAssets.count != 0 {
        uploadButton.isValid = true
        uploadButton.alpha = 1
      }
      else {
        uploadButton.isValid = false
        uploadButton.alpha = 0.5
      }
    }
  }

  private lazy var fetchOptions: PHFetchOptions = {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    return fetchOptions
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    getPhotoLibraryPermission { [unowned self] status in
      switch status {
      case .authorized,
           .limited:
        self.getPhotoAssets()
      default:
        Logger.shared.debug("\(status)")
      }
    }
    uploadButton.isValid = false
    uploadButton.alpha = 0.5

    if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
      let horizontalSpacing = flowLayout.scrollDirection == .vertical ? flowLayout.minimumInteritemSpacing : flowLayout
        .minimumLineSpacing
      let cellWidth = (view.frame.width - max(0, 3 - 1) * horizontalSpacing) / 3
      flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
    }

    activityIndicator.center = self.view.center
    self.view.addSubview(activityIndicator)
    countLabel.text = "\(selectedPhotoAssets.count)/\(maxSelectedImageCount)"
    footerView.isHidden = isHiddenFooterView
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  @IBAction
  private func upload(_: UIButton) {
    loading.setAppearance(isHidden: false)

    DispatchQueue.global().async {
      let selectedImages = self.selectedPhotoAssets
        .map { photoAsset in
          photoAsset.convertAssetToImage()
        }
      
      let selectedImageIDs = self.selectedPhotoAssets
        .map { photoAsset in
          photoAsset.localIdentifier
        }

      DispatchQueue.main.async {
        self.loading.setAppearance(isHidden: true)
        self.completion?(selectedImages)
        self.completionWithLocalIdentifier?(selectedImageIDs)
      }
    }
  }

  private func getPhotoAssets() {
    PHPhotoLibrary.shared().register(self)
    photoAssets = PHAsset.fetchAssets(with: fetchOptions)
    collectionView.reloadData()
  }

  private func getPhotoLibraryPermission(_ callback: @escaping (_ status: PHAuthorizationStatus) -> Void) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { authorizationStatus in
      DispatchQueue.main.async {
        callback(authorizationStatus)
      }
    }
  }

  private func getAssets(fromCollection collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
    PHAsset.fetchAssets(in: collection, options: fetchOptions)
  }

  private func showCamera() {
    let cameraPicer = UIImagePickerController()
    cameraPicer.sourceType = .camera
    cameraPicer.delegate = delegate
    self.present(cameraPicer, animated: true)
  }

  private func showCountLimitAlert() -> Bool {
    if selectedPhotoAssets.count >= maxSelectedImageCount {
      showToast(
        Localize.string("common_photo_upload_limit_reached", "\(Configuration.uploadImageCountLimit)"),
        barImg: .failed)
      return false
    }

    return true
  }

  private func showFormatInvalidAlert(asset: PHAsset) -> Bool {
    guard
      let fileName = asset.value(forKey: "filename") as? String,
      let fileExtension = fileName.split(separator: ".").last?.uppercased()
    else {
      return false
    }

    if !Self.availableImageFormat.contains(String(fileExtension)) {
      showToast(Localize.string("deposit_file_format_invalid"), barImg: .failed)
      return false
    }

    return true
  }

  private func showSizeLimitAlert(asset: PHAsset) -> Bool {
    let resources = PHAssetResource.assetResources(for: asset)
    var sizeOnDisk: Int64? = 0
    if let resource = resources.first {
      let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
      sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
      if Units(bytes: sizeOnDisk!).megabytes > Double(Configuration.uploadImageMBSizeLimit) {
        showToast(Localize.string("deposit_execeed_limitation"), barImg: .failed)
        return false
      }
    }

    return true
  }

  private func addSelectedImage(cell: CollectionViewCell, index: Int) {
    let selectedImage = UIImageView(frame: cell.imgBackground.frame)
    selectedImage.tag = index
    selectedImage.image = UIImage(named: "iconPhotoSelected32")
    selectedImage.contentMode = .center
    selectedImage.backgroundColor = UIColor(red: 19 / 255, green: 19 / 255, blue: 19 / 255, alpha: 0.7)
    cell.addSubview(selectedImage)
  }
}

extension ImagePickerViewController: PHPhotoLibraryChangeObserver {
  func photoLibraryDidChange(_: PHChange) {
    DispatchQueue.main.async {
      self.photoAssets = PHAsset.fetchAssets(with: self.fetchOptions)
      self.collectionView.reloadData()
    }
  }
}

extension PHAssetCollection {
  func getPhotosCount(fetchOptions: PHFetchOptions?) -> Int {
    let options = fetchOptions ?? PHFetchOptions()
    let result = PHAsset.fetchAssets(in: self, options: options)
    return result.count
  }
}

extension ImagePickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
    photoAssets.count + 1
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard
      let cell = collectionView
        .dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as? CollectionViewCell
    else { fatalError() }
    if indexPath.item == 0 {
      cell.cameraView.isHidden = false
      cell.imgBackground.image = nil
      if let image = cameraImage {
        cell.cameraImageView.image = image
      }

      if let text = cameraText {
        cell.cameraLabel.text = text
      }
    }
    else {
      let currentPhoto = photoAssets.object(at: indexPath.item - 1)
      cell.cameraView.isHidden = true
      cell.indexPath = indexPath
      cell.photoAsset = currentPhoto

      for view in cell.subviews {
        if view.tag != 0 {
          view.removeFromSuperview()
        }
      }

      if selectedPhotoAssets.contains(currentPhoto) {
        addSelectedImage(cell: cell, index: indexPath.item)
      }
    }

    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let newCell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell else { return }
    guard indexPath.item != 0 else {
      switch cameraType {
      case .general:
        showCamera()
      case .qrCode:
        let qrCodeView = UIStoryboard(name: "ImagePicker", bundle: nil)
          .instantiateViewController(withIdentifier: "qrCodeViewController") as? qrCodeViewController
        qrCodeView?.qrCodeCompletion = self.qrCodeCompletion
        NavigationManagement.sharedInstance.pushViewController(vc: qrCodeView!)
      }

      return
    }

    let index = indexPath.item - 1
    switch cameraType {
    case .general:
      let asset = photoAssets.object(at: index)
      if selectedPhotoAssets.contains(asset) {
        selectedPhotoAssets = selectedPhotoAssets.filter { $0 != asset }
        for view in newCell.subviews {
          if view.tag == indexPath.item {
            view.removeFromSuperview()
          }
        }
      }
      else {
        guard
          showCountLimitAlert(), showSizeLimitAlert(asset: asset),
          showFormatInvalidAlert(asset: asset) else { return }
        selectedPhotoAssets.append(asset)
        addSelectedImage(cell: newCell, index: indexPath.item)
      }

      countLabel.text = "\(selectedPhotoAssets.count)/\(maxSelectedImageCount)"
    case .qrCode:
      let asset = photoAssets.object(at: index)
      guard showFormatInvalidAlert(asset: asset) else { return }
      completion?([asset.convertAssetToImage()])
    }
  }
}

class AlbumModel {
  let name: String
  let count: Int
  let collection: PHAssetCollection
  let image: UIImage
  init(name: String, count: Int, collection: PHAssetCollection, image: UIImage) {
    self.name = name
    self.count = count
    self.collection = collection
    self.image = image
  }

  static func == (album1: AlbumModel, album2: AlbumModel) -> Bool {
    album1.name == album2.name
  }
}

enum CameraType {
  case general
  case qrCode
}

class CornerRect: UIView {
  var color = UIColor.black {
    didSet {
      setNeedsDisplay()
    }
  }

  var radius: CGFloat = 0 {
    didSet {
      setNeedsDisplay()
    }
  }

  var thickness: CGFloat = 2 {
    didSet {
      setNeedsDisplay()
    }
  }

  var length: CGFloat = 60 {
    didSet {
      setNeedsDisplay()
    }
  }

  override func draw(_: CGRect) {
    color.set()

    let t2 = thickness / 2
    let path = UIBezierPath()
    // Top left
    path.move(to: CGPoint(x: t2, y: length + radius + t2))
    path.addLine(to: CGPoint(x: t2, y: radius + t2))
    path.addArc(
      withCenter: CGPoint(x: radius + t2, y: radius + t2),
      radius: radius,
      startAngle: CGFloat.pi,
      endAngle: CGFloat.pi * 3 / 2,
      clockwise: true)
    path.addLine(to: CGPoint(x: length + radius + t2, y: t2))

    // Top right
    path.move(to: CGPoint(x: frame.width - t2, y: length + radius + t2))
    path.addLine(to: CGPoint(x: frame.width - t2, y: radius + t2))
    path.addArc(
      withCenter: CGPoint(x: frame.width - radius - t2, y: radius + t2),
      radius: radius,
      startAngle: 0,
      endAngle: CGFloat.pi * 3 / 2,
      clockwise: false)
    path.addLine(to: CGPoint(x: frame.width - length - radius - t2, y: t2))

    // Bottom left
    path.move(to: CGPoint(x: t2, y: frame.height - length - radius - t2))
    path.addLine(to: CGPoint(x: t2, y: frame.height - radius - t2))
    path.addArc(
      withCenter: CGPoint(x: radius + t2, y: frame.height - radius - t2),
      radius: radius,
      startAngle: CGFloat.pi,
      endAngle: CGFloat.pi / 2,
      clockwise: false)
    path.addLine(to: CGPoint(x: length + radius + t2, y: frame.height - t2))

    // Bottom right
    path.move(to: CGPoint(x: frame.width - t2, y: frame.height - length - radius - t2))
    path.addLine(to: CGPoint(x: frame.width - t2, y: frame.height - radius - t2))
    path.addArc(
      withCenter: CGPoint(x: frame.width - radius - t2, y: frame.height - radius - t2),
      radius: radius,
      startAngle: 0,
      endAngle: CGFloat.pi / 2,
      clockwise: true)
    path.addLine(to: CGPoint(x: frame.width - length - radius - t2, y: frame.height - t2))

    path.lineWidth = thickness
    path.stroke()
  }
}
