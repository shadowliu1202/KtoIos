import Combine
import SwiftUI
import UIKit

class QRCodePickerViewController: UIViewController {
  private let viewModel = ImagePickerViewModel()
  
  private let readImageOnSuccess: (_ qrCode: String) -> Void
  private let readImageOnFailure: () -> Void

  private var cancellables = Set<AnyCancellable>()
  
  init(
    readImageOnSuccess: @escaping (_ qrCode: String) -> Void,
    readImageOnFailure: @escaping () -> Void)
  {
    self.readImageOnSuccess = readImageOnSuccess
    self.readImageOnFailure = readImageOnFailure
    
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
      ImagePickerView(
        viewModel: viewModel,
        pickerMode: .qrCode,
        cameraCellOnTap: { [unowned self] in
          showQRCodeCamara()
        },
        imageCellOnTap: { [unowned self] imageAsset, _ in
          readQRCode(from: imageAsset.image, onSuccess: readImageOnSuccess, onFailure: readImageOnFailure)
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
  
  private func showQRCodeCamara() {
    let qrCodeVC = qrCodeViewController.initFrom(storyboard: "ImagePicker")
    qrCodeVC.qrCodeCompletion = { [self] qrCode in
      readImageOnSuccess(qrCode)
    }
    
    navigationController?.pushViewController(qrCodeVC, animated: true)
  }
  
  func readQRCode(
    from image: UIImage,
    onSuccess: (_ qrCode: String) -> Void,
    onFailure: () -> Void)
  {
    if
      let features = detectQRCode(image),
      !features.isEmpty
    {
      for case let row as CIQRCodeFeature in features {
        onSuccess(row.messageString ?? "")
      }
    }
    else {
      onFailure()
    }
  }

  private func detectQRCode(_ image: UIImage) -> [CIFeature]? {
    guard let ciImage = CIImage(image: image)
    else {
      return nil
    }

    var options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]

    let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(), options: options)

    if ciImage.properties.keys.contains(kCGImagePropertyOrientation as String) {
      options = [CIDetectorImageOrientation: ciImage.properties[kCGImagePropertyOrientation as String] ?? 1]
    }
    else {
      options = [CIDetectorImageOrientation: 1]
    }

    let features = qrDetector?.features(in: ciImage, options: options)
    return features
  }
}
