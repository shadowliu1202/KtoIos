import Foundation
import RxSwift
import SharedBu

class DepositLogViewModel: CollectErrorViewModel {
  static let imageMBSizeLimit = 20
  static let selectedImageCountLimit = 3

  private let depositService: IDepositAppService

  private let disposeBag = DisposeBag()

  let recordDetailRefreshTrigger = PublishSubject<Void>()

  var uploadImageDetail: [Int: UploadImageDetail] = [:]
  var pagination: Pagination<PaymentLogDTO.GroupLog>!
  var dateBegin: Date?
  var dateEnd: Date?
  var status: [PaymentLogDTO.LogStatus] = []

  init(_ depositService: IDepositAppService) {
    self.depositService = depositService

    super.init()

    pagination = .init(observable: { [unowned self] page in
      self.getDepositRecords(page: Int32(page))
        .do(onError: { error in
          self.pagination.error.onNext(error)
        }).catch({ _ -> Observable<[PaymentLogDTO.GroupLog]> in
          Observable.empty()
        })
    })
  }

  deinit {
    print("\(type(of: self)) deinit")
  }
}

// MARK: - API

extension DepositLogViewModel {
  func bindingImageWithDepositRecord(displayId: String, portalImages: [UploadImage]) -> Completable {
    Single.from(
      depositService.addSupplementaryDocument(
        displayId: displayId,
        images: portalImages))
      .asCompletable()
  }

  func getDepositFiatLog(transactionId: String) -> Observable<PaymentLogDTO.FiatLog> {
    recordDetailRefreshTrigger
      .flatMapLatest { [unowned self] in
        Observable.from(self.depositService.getFiatLog(displayId: transactionId))
      }
  }

  func getDepositCryptoLog(transactionId: String) -> Observable<PaymentLogDTO.CryptoLog> {
    Observable.from(
      depositService.getCryptoLog(displayId: transactionId))
  }

  func getDepositRecords(page: Int32 = 1) -> Observable<[PaymentLogDTO.GroupLog]> {
    let beginDate = (self.dateBegin ?? Date().getPastSevenDate()).convertToKotlinx_datetimeLocalDate()
    let endDate = (self.dateEnd ?? Date().convertdateToUTC()).convertToKotlinx_datetimeLocalDate()
    let statusSet = Set(status.map({ $0 }))

    return Single.from(
      depositService.getPaymentLogs(
        filters: PaymentLogDTO.LogFilter(
          page: page,
          from: beginDate,
          to: endDate,
          filter: statusSet)))
      .map { $0.compactMap { $0 as? PaymentLogDTO.GroupLog } }
      .asObservable()
  }

  func getCashLogSummary() -> Single<CurrencyUnit> {
    let beginDate = (self.dateBegin ?? Date().getPastSevenDate()).convertToKotlinx_datetimeLocalDate()
    let endDate = (self.dateEnd ?? Date().convertdateToUTC()).convertToKotlinx_datetimeLocalDate()

    return Single.from(
      depositService.getPaymentSummary(from: beginDate, to: endDate))
  }

  func getDepositLog(_ displayId: String) -> Single<PaymentLogDTO.Log> {
    Single.from(
      depositService.getPaymentLog(displayId: displayId))
  }
}
