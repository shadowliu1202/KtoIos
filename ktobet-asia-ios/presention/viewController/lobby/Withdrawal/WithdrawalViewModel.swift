import Foundation
import RxSwift
import SharedBu

class WithdrawalViewModel {
    static let imageMBSizeLimit = 20
    static let selectedImageCountLimit = 3
    private var withdrawalUseCase: WithdrawalUseCase!
    private var localStorageRepository: LocalStorageRepository!
    lazy var localCurrency = localStorageRepository.getLocalCurrency()
    var uploadImageDetail: [Int: UploadImageDetail] = [:]
    var pagination: Pagination<WithdrawalRecord>!
    var status: [TransactionStatus] = []
    var dateBegin: Date?
    var dateEnd: Date?
    
    init(withdrawalUseCase: WithdrawalUseCase, localStorageRepository: LocalStorageRepository) {
        self.withdrawalUseCase = withdrawalUseCase
        self.localStorageRepository = localStorageRepository
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
    
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail> {
        return self.withdrawalUseCase.getWithdrawalRecordDetail(transactionId: transactionId, transactionTransactionType: transactionTransactionType)
    }
    
    func getWithdrawalRecords(page: String = "1") -> Observable<[WithdrawalRecord]> {
        let beginDate = (self.dateBegin ?? Date().getPastSevenDate())
        let endDate = (self.dateEnd ?? Date().convertdateToUTC())
        return withdrawalUseCase.getWithdrawalRecords(page: page, dateBegin: beginDate, dateEnd: endDate, status: self.status).asObservable()
    }
    
    func cancelWithdrawal(ticketId: String) -> Completable {
        return self.withdrawalUseCase.cancelWithdrawal(ticketId: ticketId)
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return withdrawalUseCase.bindingImageWithWithdrawalRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
    
    func cryptoLimitTransactions() -> Single<CryptoWithdrawalLimitLog> {
        return withdrawalUseCase.getCryptoLimitTransactions()
    }
}
