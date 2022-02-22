import Foundation
import SharedBu
import RxSwift

class DepositLogViewModel {
    static let imageMBSizeLimit = 20
    static let selectedImageCountLimit = 3
    private var depositService: IDepositAppService!
    
    var uploadImageDetail: [Int: UploadImageDetail] = [:]
    lazy var recentPaymentLogs = RxSwift.Observable.from(depositService.getRecentPaymentLogs()).map{ $0.compactMap{ $0 as? PaymentLogDTO.Log } }
    var pagination: Pagination<PaymentLogDTO.GroupLog>!
    var dateBegin: Date?
    var dateEnd: Date?
    var status: [PaymentLogDTO.LogStatus] = []
    
    init(_ depositService: IDepositAppService) {
        self.depositService = depositService
        pagination = Pagination<PaymentLogDTO.GroupLog>(callBack: {(page) -> Observable<[PaymentLogDTO.GroupLog]> in
            self.getDepositRecords(page: Int32(page))
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError({ error -> Observable<[PaymentLogDTO.GroupLog]> in
                    Observable.empty()
                })
        })
    }
    
    func bindingImageWithDepositRecord(displayId: String, portalImages: [UploadImage]) -> Completable {
        Single.from(depositService.addSupplementaryDocument(displayId: displayId, images: portalImages)).asCompletable()
    }
    
    func getDepositFiatLog(transactionId: String) -> Observable<PaymentLogDTO.FiatLog> {
        return Observable.from(depositService.getFiatLog(displayId: transactionId))
    }
    
    func getDepositCryptoLog(transactionId: String) -> Observable<PaymentLogDTO.CryptoLog> {
        return Observable.from(depositService.getCryptoLog(displayId: transactionId))
    }
    
    func getDepositRecords(page: Int32 = 1) -> Observable<[PaymentLogDTO.GroupLog]> {
        let beginDate = (self.dateBegin ?? Date().getPastSevenDate()).convertToKotlinx_datetimeLocalDate()
        let endDate = (self.dateEnd ?? Date().convertdateToUTC()).convertToKotlinx_datetimeLocalDate()
        let statusSet = Set(status.map({$0}))
        return RxSwift.Single.from(depositService.getPaymentLogs(filters: PaymentLogDTO.LogFilter(page: page, from: beginDate, to: endDate, filter: statusSet))).map({$0.compactMap({$0 as? PaymentLogDTO.GroupLog})}).asObservable()
    }
    
     func getCashLogSummary() -> Single<CurrencyUnit> {
         let beginDate = (self.dateBegin ?? Date().getPastSevenDate()).convertToKotlinx_datetimeLocalDate()
         let endDate = (self.dateEnd ?? Date().convertdateToUTC()).convertToKotlinx_datetimeLocalDate()
         return RxSwift.Single.from(depositService.getPaymentSummary(from: beginDate, to: endDate))
     }
}
