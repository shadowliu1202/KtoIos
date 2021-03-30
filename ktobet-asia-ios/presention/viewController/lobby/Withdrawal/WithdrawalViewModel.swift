import Foundation
import RxSwift
import share_bu

class WithdrawalViewModel {
    static let imageLimitSize = 20000000
    private var withdrawalUseCase: WithdrawalUseCase!
    var uploadImageDetail: [Int: UploadImageDetail] = [:]
    var pagination: Pagination<WithdrawalRecord>!
    var status: [TransactionStatus] = []
    var dateBegin: Date?
    var dateEnd: Date?
    
    init(withdrawalUseCase: WithdrawalUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
        pagination = Pagination<WithdrawalRecord>(callBack: {(page) -> Observable<[WithdrawalRecord]> in
            self.getWithdrawalRecords(page: String(page))
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError({ error -> Observable<[WithdrawalRecord]> in
                    Observable.empty()
                })
        })
    }
    
    func withdrawalAccounts() -> Single<[WithdrawalAccount]> {
        return self.withdrawalUseCase.getWithdrawalAccounts()
    }
    
    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        return self.withdrawalUseCase.getWithdrawalLimitation()
    }
    
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]> {
        return self.withdrawalUseCase.getWithdrawalRecords()
    }
    
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalRecordDetail> {
        return self.withdrawalUseCase.getWithdrawalRecordDetail(transactionId: transactionId, transactionTransactionType: transactionTransactionType)
    }
    
    func getWithdrawalRecords(page: String = "1") -> Observable<[WithdrawalRecord]> {
        let beginDate = (self.dateBegin ?? Date().getPastSevenDate()).formatDateToStringToSecond(with: "-")
        let endDate = (self.dateEnd ?? Date().convertdateToUTC()).formatDateToStringToSecond(with: "-")
        return withdrawalUseCase.getWithdrawalRecords(page: page, dateBegin: beginDate, dateEnd: endDate, status: self.status).asObservable()
    }
    
    func cancelWithdrawal(ticketId: String) -> Completable {
        return self.withdrawalUseCase.cancelWithdrawal(ticketId: ticketId)
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return withdrawalUseCase.bindingImageWithWithdrawalRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
}
