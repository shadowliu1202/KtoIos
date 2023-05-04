import Foundation
import RxSwift
import SharedBu

protocol WithdrawalRecordDetailViewModelProtocol: AnyObject {
  var log: WithdrawalDto.Log? { get }
  var remarks: [RecordRemark.Previous.Model] { get }
  var selectedImages: [RecordRemark.Uploader.Model] { get set }

  var supportLocale: SupportLocale { get }
  var httpHeaders: [String: String] { get }
  var isCancelable: Bool { get }
  var isAllowConfirm: Bool { get }

  func prepareForAppear(transactionId: String)

  func observeFiatLog()
  func confirmUploadedImages()
  func cancelWithdrawal()
}

class WithdrawalRecordDetailViewModel:
  CollectErrorViewModel,
  ObservableObject,
  WithdrawalRecordDetailViewModelProtocol,
  RecordUploader
{
  @Published private(set) var log: WithdrawalDto.Log?
  @Published private(set) var remarks: [RecordRemark.Previous.Model] = []
  @Published private(set) var isCancelable = false

  @Published var selectedImages: [RecordRemark.Uploader.Model] = []

  static let imageMBSizeLimit = 20
  static let selectedImageCountLimit = 3

  private let withdrawalService: IWithdrawalAppService
  private let httpClient: HttpClient

  let imageUseCase: UploadImageUseCase
  let disposeBag = DisposeBag()

  private var transactionId = ""

  private var isSubmitButtonDisable = false

  var httpHeaders: [String: String] {
    httpClient.headers
  }

  var isAllowConfirm: Bool {
    !isSubmitButtonDisable &&
      !selectedImages.isEmpty &&
      selectedImages.filter { $0.isUploading }.isEmpty
  }

  let supportLocale: SupportLocale

  init(
    withdrawalService: IWithdrawalAppService,
    imageUseCase: UploadImageUseCase,
    httpClient: HttpClient,
    playerConfig: PlayerConfiguration)
  {
    self.withdrawalService = withdrawalService
    self.imageUseCase = imageUseCase
    self.httpClient = httpClient
    self.supportLocale = playerConfig.supportLocale
  }

  func prepareForAppear(transactionId: String) {
    self.transactionId = transactionId
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - API

extension WithdrawalRecordDetailViewModel {
  func observeFiatLog() {
    Observable
      .from(withdrawalService.getFiatLog(displayId: transactionId))
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        guard let self else { return }

        self.log = $0.log
        self.isCancelable = $0.isCancelable
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
    Completable.from(
      withdrawalService.addSupplementaryDocument(
        displayId: transactionId,
        images: selectedImages.compactMap { $0.detail?.portalImage }))
      .subscribe(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  func cancelWithdrawal() {
    Completable.from(
      withdrawalService.cancelWithdrawRequest(displayId: transactionId))
      .do(
        onSubscribe: { [weak self] in
          self?.isSubmitButtonDisable = true
        },
        onDispose: { [weak self] in
          self?.isSubmitButtonDisable = false
        })
      .subscribe(onError: { [weak self] in
        self?.errorsSubject.onNext($0)
      })
      .disposed(by: disposeBag)
  }

  func getWithdrawalLog(_ displayId: String) -> Single<WithdrawalDto.Log> {
    Single.from(
      withdrawalService.getLog(displayId: displayId))
  }
}
