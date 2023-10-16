import RxSwift
import sharedbu
import UIKit

class DepositRecordDetailViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected private var alert: AlertProtocol
  @Injected private var viewModel: DepositRecordDetailViewModel

  private let transactionId: String
  private let disposeBag = DisposeBag()

  private(set) var imagePickable: ImagePickable?

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
    imagePickable = .init(
      target: self,
      alert: alert,
      didSelected: { [weak self] fromCamera, images in
        self?.viewModel.prepareSelectedImages(images, shouldReplaceAll: fromCamera)
      })

    addSubView(
      from: { [unowned self] in
        DepositRecordDetailView(
          viewModel: self.viewModel,
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
    imagePickable?.pushImagePicker(
      currentSelectedImageCount: viewModel.selectedImages.count)
  }
}
