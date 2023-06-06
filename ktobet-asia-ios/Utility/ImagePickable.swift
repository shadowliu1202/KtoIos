import UIKit

class ImagePickable: NSObject {
  private let selectedImageCountLimit: Int
  private let imageMBSizeLimit: Int

  private var didSelected: (_ fromCamera: Bool, _ images: [UIImage]) -> Void

  private weak var alert: AlertProtocol?
  private weak var target: UIViewController?

  init(
    target: UIViewController? = nil,
    alert: AlertProtocol,
    selectedImageCountLimit: Int,
    imageMBSizeLimit: Int,
    didSelected: @escaping (_ fromCamera: Bool, _ images: [UIImage]) -> Void)
  {
    self.alert = alert
    self.target = target
    self.selectedImageCountLimit = selectedImageCountLimit
    self.imageMBSizeLimit = imageMBSizeLimit
    self.didSelected = didSelected
  }

  func pushImagePicker(currentSelectedImageCount: Int) {
    guard currentSelectedImageCount < selectedImageCountLimit
    else {
      alert?.show(
        Localize.string("common_tip_title_warm"),
        Localize.string(
          "common_photo_upload_limit_reached",
          ["\(selectedImageCountLimit)"]),
        confirm: nil,
        cancel: nil)
      return
    }

    let imagePickerViewController = ImagePickerViewController.initFrom(storyboard: "ImagePicker")

    imagePickerViewController.delegate = self
    imagePickerViewController.imageLimitMBSize = DepositRecordDetailViewModel.imageMBSizeLimit
    imagePickerViewController.selectedImageLimitCount = selectedImageCountLimit - currentSelectedImageCount
    imagePickerViewController.allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]

    imagePickerViewController.completion = { [weak self] images in
      guard let self else { return }
      NavigationManagement.sharedInstance.popViewController()
      self.didSelected(false, images)
    }

    imagePickerViewController.showImageCountLimitAlert = { [weak self] _ in
      self?.target?.showToast(
        Localize.string(
          "common_photo_upload_limit_reached",
          ["\(imagePickerViewController.selectedImageLimitCount)"]),
        barImg: .failed)
    }

    imagePickerViewController.showImageSizeLimitAlert = { [weak self] _ in
      self?.target?.showToast(Localize.string("deposit_execeed_limitation"), barImg: .failed)
    }

    imagePickerViewController.showImageFormatInvalidAlert = { [weak self] _ in
      self?.target?.showToast(Localize.string("common_image_format_not_support"), barImg: .failed)
    }

    NavigationManagement.sharedInstance.pushViewController(vc: imagePickerViewController)
  }
}

// MARK: Camera event

extension ImagePickable:
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  func imagePickerController(
    _: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
  {
    target?.dismiss(animated: true) { [weak self] in
      NavigationManagement.sharedInstance.popViewController()

      guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

      DispatchQueue.main.async {
        self?.didSelected(true, [image])
      }
    }
  }

  func imagePickerControllerDidCancel(_: UIImagePickerController) {
    target?.dismiss(animated: true, completion: nil)
  }
}
