import Foundation
import RxSwift
import sharedbu

protocol DepositRecordDetailViewModelProtocol: AnyObject {
    var log: PaymentLogDTO.Log? { get }
    var remarks: [RecordRemark.Previous.Model] { get }
    var selectedImages: [RecordRemark.Uploader.Model] { get set }

    var supportLocale: SupportLocale { get }
    var isAllowConfirm: Bool { get }

    func prepareForAppear(transactionId: String)

    func observeFiatLog()
    func confirmUploadedImages()
}

class DepositRecordDetailViewModel:
    CollectErrorViewModel,
    ObservableObject,
    DepositRecordDetailViewModelProtocol,
    RecordUploader
{
    @Published private(set) var log: PaymentLogDTO.Log?
    @Published private(set) var remarks: [RecordRemark.Previous.Model] = []

    @Published var selectedImages: [RecordRemark.Uploader.Model] = []

    private let depositService: IDepositAppService
    private let httpClient: HttpClient

    let imageUseCase: UploadImageUseCase
    let disposeBag = DisposeBag()

    private var transactionId = ""

    var isAllowConfirm: Bool {
        !selectedImages.isEmpty && selectedImages.filter { $0.isUploading }.isEmpty
    }

    let supportLocale: SupportLocale

    init(
        depositService: IDepositAppService,
        imageUseCase: UploadImageUseCase,
        httpClient: HttpClient,
        playerConfig: PlayerConfiguration)
    {
        self.depositService = depositService
        self.imageUseCase = imageUseCase
        self.httpClient = httpClient
        self.supportLocale = playerConfig.supportLocale
    }

    func prepareForAppear(transactionId: String) {
        self.transactionId = transactionId
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
                images: selectedImages.compactMap { $0.detail }))
            .subscribe(onFailure: { [weak self] in
                self?.errorsSubject.onNext($0)
            })
            .disposed(by: disposeBag)
    }

    func getDepositLog(_ displayId: String) -> Single<PaymentLogDTO.Log> {
        Single.from(
            depositService.getPaymentLog(displayId: displayId))
    }
}
