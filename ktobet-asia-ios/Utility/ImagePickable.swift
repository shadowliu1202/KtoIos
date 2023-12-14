import UIKit

class ImagePickable: NSObject {
  private var didSelected: (_ fromCamera: Bool, _ images: [UIImage]) -> Void

  private let alert: AlertProtocol
  private let target: UIViewController

  init(
    target: UIViewController,
    alert: AlertProtocol,
    didSelected: @escaping (_ fromCamera: Bool, _ images: [UIImage]) -> Void)
  {
    self.alert = alert
    self.target = target
    self.didSelected = didSelected
  }

  func pushImagePicker(currentSelectedImageCount: Int) {
    guard currentSelectedImageCount < Configuration.uploadImageCountLimit
    else {
      alert.show(
        Localize.string("common_tip_title_warm"),
        Localize.string(
          "common_photo_upload_limit_reached",
          ["\(Configuration.uploadImageCountLimit)"]),
        confirm: nil,
        cancel: nil)
      return
    }
    
    let photoPickerVC = PhotoPickerViewController(
      maxCount: Configuration.uploadImageCountLimit - currentSelectedImageCount,
      selectImagesOnComplete: { [weak self] imageAssets in
        guard let self else { return }
        
        let selectedImages = imageAssets.map { $0.image }
        self.didSelected(false, selectedImages)
        NavigationManagement.sharedInstance.viewController = self.target
      })
    
    target.navigationController?.pushViewController(photoPickerVC, animated: true)
  }
}
