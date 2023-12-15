import Foundation
import Photos
import UIKit

class PhotoPickerViewController: UIViewController {
  private let viewModel = ImagePickerViewModel()
  
  private let maxCount: Int
  private let maxImageSizeInMB = Configuration.uploadImageMBSizeLimit
  private let selectImagesOnComplete: (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void
  
  init(
    maxCount: Int,
    selectImagesOnComplete: @escaping (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void)
  {
    self.maxCount = maxCount
    self.selectImagesOnComplete = selectImagesOnComplete
    
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
  }
  
  private func setupUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    
    addSubView(
      PhotoPickerView(
        viewModel: viewModel,
        maxCount: maxCount,
        maxImageSizeInMB: maxImageSizeInMB,
        cameraCellOnTap: { [unowned self] in
          showCamera()
        },
        countLimitOnHit: { [unowned self] in
          showCountLimitAlert()
        },
        invalidFormatOnHit: { [unowned self] in
          showInvalidFormatAlert()
        },
        imageSizeLimitOnHit: { [unowned self] in
          showSizeLimitAlert()
        },
        submitButtonOnTap: { [unowned self] in
          selectImagesOnComplete($0)
          navigationController?.popViewController(animated: true)
        }),
      to: view)
  }
  
  private func showCamera() {
    let cameraPicer = CustomImagePickerController()
    cameraPicer.sourceType = .camera
    cameraPicer.delegate = self
    present(cameraPicer, animated: true)
  }
  
  private func showCountLimitAlert() {
    showToast(
      Localize.string("common_photo_upload_limit_reached", "\(maxCount)"),
      barImg: .failed)
  }
  
  private func showInvalidFormatAlert() {
    showToast(Localize.string("deposit_file_format_invalid"), barImg: .failed)
  }
  
  private func showSizeLimitAlert() {
    showToast(Localize.string("deposit_execeed_limitation"), barImg: .failed)
  }
}

extension PhotoPickerViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
  func imagePickerController(
    _: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
  {
    if let image = info[.originalImage] as? UIImage {
      UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    dismiss(animated: true)
  }
  
  @objc
  func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo _: UnsafeRawPointer) {
    if let error {
      Logger.shared.error(error)
    }
    else {
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchOptions.fetchLimit = 1
      let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      if let lastAsset = fetchResult.firstObject {
        selectImagesOnComplete([ImagePickerView.ImageAsset(
          localIdentifier: lastAsset.localIdentifier,
          fileName: viewModel.requestImageFileName(asset: lastAsset),
          image: image,
          imageSizeInMB: viewModel.requestImageSizeInMB(asset: lastAsset))])
        
        navigationController?.popViewController(animated: true)
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
}
