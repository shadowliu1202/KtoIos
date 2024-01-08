import Combine
import Foundation
import Photos
import UIKit

class PhotoPickerViewController: UIViewController {
  private let viewModel = ImagePickerViewModel()
  
  private let maxCount: Int
  private let maxImageSizeInMB = Configuration.uploadImageMBSizeLimit
  private let selectImagesOnComplete: (_ selectedImages: [ImagePickerView.ImageAsset]) -> Void
  
  private var cancellables = Set<AnyCancellable>()
  
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
    
    setupAlbumMenu()
    
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
          navigationController?.popViewController(animated: true)
          selectImagesOnComplete($0)
        }),
      to: view)
  }
  
  private func setupAlbumMenu() {
    let button = createMenuButton()
    setMenu(to: button)
    
    let titleView = UIView()
    titleView.addSubview(button)

    self.navigationItem.titleView = titleView
    
    updateTitleOnSelectedAlbumChange(button, titleView)
  }
  
  private func createMenuButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.setTitle("", for: .normal)
    button.titleLabel?.font = UIFont(name: "PingFangSC-Semibold", size: 16)
    button.setTitleColor(.greyScaleWhite, for: .normal)
    
    button.setImage(UIImage(named: "DropDownWhite"), for: .normal)
    button.adjustsImageWhenHighlighted = false
    button.semanticContentAttribute = .forceRightToLeft
    button.imageEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 0)
    
    button.showsMenuAsPrimaryAction = true
    
    return button
  }
  
  private func setMenu(to button: UIButton) {
    viewModel.$albums
      .sink(receiveValue: { [viewModel] in
        let menuItems = $0.map { album in
          UIAction(
            title: album.localizedTitle ?? "",
            handler: { _ in
              viewModel.setSelectedAlbum(album)
            })
        }
        
        let menu = UIMenu(children: menuItems)
        button.menu = menu
      })
      .store(in: &cancellables)
  }
  
  private func updateTitleOnSelectedAlbumChange(_ button: UIButton, _ titleView: UIView) {
    viewModel.$selectedAlbum
      .compactMap { $0 }
      .sink(receiveValue: {
        button.setTitle($0.localizedTitle, for: .normal)
        button.sizeToFit()
        titleView.frame = CGRect(x: 0, y: 0, width: button.frame.width, height: button.frame.height)
      })
      .store(in: &cancellables)
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
        selectImagesOnComplete([ImagePickerView.ImageAsset(asset: lastAsset, image: image)])
        
        navigationController?.popViewController(animated: true)
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
}
