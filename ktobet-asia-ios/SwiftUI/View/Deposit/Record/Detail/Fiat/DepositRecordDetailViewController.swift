import RxSwift
import SharedBu
import UIKit

class DepositRecordDetailViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol
  @Injected private var viewModel: DepositRecordDetailViewModel
  @Injected private var playerConfig: PlayerConfiguration

  private let transactionId: String

  private let disposeBag = DisposeBag()

  private lazy var toastView = ToastView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 48))

  init(
    transactionId: String,
    alert: AlertProtocol? = nil,
    viewModel: DepositRecordDetailViewModel? = nil)
  {
    self.transactionId = transactionId

    if let alert {
      self._alert.wrappedValue = alert
    }

    if let viewModel {
      self._viewModel.wrappedValue = viewModel
    }

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension DepositRecordDetailViewController {
  private func setupUI() {
    addSubView(
      from: { [unowned self] in
        DepositRecordDetailView(
          viewModel: self.viewModel,
          playerConfig: self.playerConfig,
          transactionId: transactionId,
          onUploadImage: {
            self.pushImagePicker()
          },
          onClickImage: {
            NavigationManagement.sharedInstance
              .pushViewController(
                vc: ImageViewController.instantiate(url: $0, thumbnailImage: $1))
          })
      },
      to: view)
  }

  private func binding() {
    viewModel.errors()
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }

  func pushImagePicker() {
    let currentSelectedImageCount = viewModel.selectedImages.count

    guard currentSelectedImageCount < DepositRecordDetailViewModel.selectedImageCountLimit
    else {
      alert.show(
        Localize.string("common_tip_title_warm"),
        Localize.string(
          "common_photo_upload_limit_reached",
          ["\(DepositRecordDetailViewModel.selectedImageCountLimit)"]),
        confirm: nil,
        cancel: nil)
      return
    }

    let imagePickerViewController = ImagePickerViewController.initFrom(storyboard: "ImagePicker")

    imagePickerViewController.delegate = self
    imagePickerViewController.imageLimitMBSize = DepositRecordDetailViewModel.imageMBSizeLimit
    imagePickerViewController.selectedImageLimitCount = DepositRecordDetailViewModel
      .selectedImageCountLimit - currentSelectedImageCount
    imagePickerViewController.allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]

    imagePickerViewController.completion = { [weak self] images in
      guard let self else { return }

      NavigationManagement.sharedInstance.popViewController()

      self.viewModel.prepareSelectedImages(images, shouldReplaceAll: false)
    }

    imagePickerViewController.showImageCountLimitAlert = { [weak self] view in
      self?.showToast(
        Localize.string(
          "common_photo_upload_limit_reached",
          ["\(imagePickerViewController.selectedImageLimitCount)"]),
        on: view)
    }

    imagePickerViewController.showImageSizeLimitAlert = { [weak self] view in
      self?.showToast(Localize.string("deposit_execeed_limitation"), on: view)
    }

    imagePickerViewController.showImageFormatInvalidAlert = { [weak self] view in
      self?.showToast(Localize.string("deposit_file_format_invalid"), on: view)
    }

    NavigationManagement.sharedInstance.pushViewController(vc: imagePickerViewController)
  }

  private func showToast(_ string: String, on view: UIView) {
    toastView.show(
      on: view,
      statusTip: string,
      img: UIImage(named: "Failed"))
  }
}

// MARK: Camera event

extension DepositRecordDetailViewController:
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  func imagePickerController(
    _: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
  {
    dismiss(animated: true) { [unowned self] in
      NavigationManagement.sharedInstance.popViewController()

      guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
      UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

      DispatchQueue.main.async {
        self.viewModel.prepareSelectedImages([image], shouldReplaceAll: true)
      }
    }
  }

  func imagePickerControllerDidCancel(_: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
}
