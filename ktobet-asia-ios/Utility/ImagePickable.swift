import UIKit

class ImagePickable: NSObject {
  private var didSelected: (_ fromCamera: Bool, _ images: [UIImage]) -> Void

  private weak var alert: AlertProtocol?
  private weak var target: UIViewController?

  init(
    target: UIViewController? = nil,
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
      alert?.show(
        Localize.string("common_tip_title_warm"),
        Localize.string(
          "common_photo_upload_limit_reached",
          ["\(Configuration.uploadImageCountLimit)"]),
        confirm: nil,
        cancel: nil)
      return
    }

    let imagePickerViewController = ImagePickerViewController.initFrom(storyboard: "ImagePicker")

    imagePickerViewController.delegate = self
    imagePickerViewController.maxSelectedImageCount = Configuration.uploadImageCountLimit - currentSelectedImageCount

    imagePickerViewController.completion = { [weak self] images in
      guard let self else { return }
      NavigationManagement.sharedInstance.popViewController()
      self.didSelected(false, images)
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
