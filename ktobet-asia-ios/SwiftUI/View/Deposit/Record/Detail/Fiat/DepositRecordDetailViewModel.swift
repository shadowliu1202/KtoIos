import Combine
import Foundation
import RxSwift
import SDWebImage
import SharedBu

protocol DepositRecordDetailViewModelProtocol: AnyObject {
  var log: PaymentLogDTO.Log? { get }
  var remarks: [DepositRecordDetailViewModel.Remark] { get }
  var selectedImages: [DepositRecordDetailViewModel.UploadImage] { get set }

  var downloadHeaders: [String: String] { get }
  var isAllowConfirm: Bool { get }

  func prepareForAppear(transactionId: String)
  func prepareSelectedImages(_ images: [UIImage], shouldReplaceAll: Bool)

  func removeSelectedImage(_ selected: DepositRecordDetailViewModel.UploadImage)

  func observeFiatLog()
  func confirmUploadedImages()
}

class DepositRecordDetailViewModel:
  CollectErrorViewModel,
  ObservableObject,
  DepositRecordDetailViewModelProtocol
{
  @Published private(set) var log: PaymentLogDTO.Log?
  @Published private(set) var remarks: [DepositRecordDetailViewModel.Remark] = []

  @Published var selectedImages: [UploadImage] = []

  static let imageMBSizeLimit = 20
  static let selectedImageCountLimit = 3

  private let depositService: IDepositAppService
  private let imageUseCase: UploadImageUseCase
  private let httpClient: HttpClient

  private let disposeBag = DisposeBag()

  private var transactionId = ""

  var downloadHeaders: [String: String] {
    httpClient.headers
  }

  var isAllowConfirm: Bool {
    !selectedImages.isEmpty && selectedImages.filter { $0.isUploading }.isEmpty
  }

  init(
    depositService: IDepositAppService,
    imageUseCase: UploadImageUseCase,
    httpClient: HttpClient)
  {
    self.depositService = depositService
    self.imageUseCase = imageUseCase
    self.httpClient = httpClient
  }

  func prepareForAppear(transactionId: String) {
    self.transactionId = transactionId
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - Model

extension DepositRecordDetailViewModel {
  struct Remark {
    let date: String
    let content: String
    var uploadedURLs: [(url: String, thumbnail: String)] = []

    init(
      updateHistory: UpdateHistory,
      host: String,
      uploadedURLs: [(url: String, thumbnail: String)]? = nil)
    {
      self.date = updateHistory.createdDate.toDateTimeString()

      if let uploadedURLs {
        self.uploadedURLs = uploadedURLs
      }
      else {
        self.uploadedURLs = Array(updateHistory.imageIds.prefix(3))
          .map {
            (url: host + $0.path(), thumbnail: host + $0.thumbnailPath() + ".jpg")
          }
      }

      self.content = [
        updateHistory.remarkLevel1,
        updateHistory.remarkLevel2,
        updateHistory.remarkLevel3
      ]
      .filter { !$0.isEmpty }
      .joined(separator: " > ")
    }
  }

  struct UploadImage: Equatable {
    let image: UIImage

    var isUploading = true
    var detail: UploadImageDetail?

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.image == rhs.image
    }
  }
}

// MARK: - API

extension DepositRecordDetailViewModel {
  func observeFiatLog() {
    Observable
      .from(depositService.getFiatLog(displayId: transactionId))
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        guard let self else { return }

        self.log = $0.log
        self.remarks = $0.updateHistories
          .map {
            .init(
              updateHistory: $0,
              host: self.httpClient.host.absoluteString)
          }
      }, onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  func confirmUploadedImages() {
    Single.from(
      depositService.addSupplementaryDocument(
        displayId: transactionId,
        images: selectedImages.compactMap { $0.detail?.portalImage }))
      .asObservable()
      .subscribe(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  private func startUploadImages(_ uploads: [UploadImage]) {
    let requests = uploads.compactMap { element -> Observable<UploadImage>? in
      guard let data = element.image.jpegData(compressionQuality: 1.0) else { return nil }

      return imageUseCase
        .uploadImage(imageData: data)
        .map {
          UploadImage(
            image: element.image,
            isUploading: false,
            detail: $0)
        }
        .do(onSuccess: { [weak self] in
          guard let index = self?.findSelectedImageIndex($0) else { return }
          self?.selectedImages[index] = $0
        }, onError: { [weak self] _ in
          self?.removeSelectedImage(element)
        })
        .asObservable()
    }

    Observable
      .combineLatest(requests)
      .subscribe(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  func getDepositLog(_ displayId: String) -> Single<PaymentLogDTO.Log> {
    Single.from(
      depositService.getPaymentLog(displayId: displayId))
  }
}

// MARK: - Data Handle

extension DepositRecordDetailViewModel {
  func prepareSelectedImages(_ images: [UIImage], shouldReplaceAll: Bool) {
    let selected = images.map { UploadImage(image: $0) }

    if shouldReplaceAll {
      selectedImages = selected
    }
    else {
      selectedImages = selectedImages + selected
    }

    startUploadImages(selected)
  }

  func removeSelectedImage(_ selected: UploadImage) {
    guard let index = findSelectedImageIndex(selected) else { return }
    selectedImages.remove(at: index)
  }

  func findSelectedImageIndex(_ selected: UploadImage) -> Int? {
    guard let index = selectedImages.firstIndex(of: selected) else { return nil }
    return index
  }
}
