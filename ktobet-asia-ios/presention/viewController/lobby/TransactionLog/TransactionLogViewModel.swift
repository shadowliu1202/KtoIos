import Foundation
import RxSwift
import SharedBu

class TransactionLogViewModel {
    private var transactionLogUseCase: TransactionLogUseCase!
    
    var pagination: Pagination<TransactionLog>!
    var from: Date? = Date().adding(value: -7, byAdding: .day)
    var to: Date? = Date()
    var balanceLogFilterType: Int? = 0
    
    init(transactionLogUseCase: TransactionLogUseCase) {
        self.transactionLogUseCase = transactionLogUseCase
        
        pagination = Pagination<TransactionLog>(callBack: {(page) -> Observable<[TransactionLog]> in
            self.searchTransactionLog(page: page)
                .do(onError: { error in
                    self.pagination.error.onNext(error)
                }).catchError({ error -> Observable<[TransactionLog]> in
                    Observable.empty()
                })
        })
    }
    
    func searchTransactionLog(from: Date, to: Date, balanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]> {
        transactionLogUseCase.searchTransactionLog(from: from, to: to, BalanceLogFilterType: balanceLogFilterType, page: page)
    }
    
    func searchTransactionLog(page: Int) -> Observable<[TransactionLog]> {
        guard let fromDate = from, let toDate = to, let filterType = balanceLogFilterType else { return Observable.error(KTOError.EmptyData)}
        return searchTransactionLog(from: fromDate, to: toDate, balanceLogFilterType: filterType, page: page).asObservable()
    }
    
    func getCashFlowSummary() -> Single<CashFlowSummary> {
        guard let fromDate = from, let toDate = to, let filterType = balanceLogFilterType else { return Single.error(KTOError.EmptyData)}
        return transactionLogUseCase.getCashFlowSummary(begin: fromDate, end: toDate, balanceLogFilterType: filterType)
    }
    
    func getCashLogSummary() -> Single<CashLogSummary> {
        guard let fromDate = from, let toDate = to else { return Single.error(KTOError.EmptyData) }
        let filterAll = CashLogFilter.all.rawValue
        return transactionLogUseCase.getCashLogSummary(begin: fromDate, end: toDate, balanceLogFilterType: filterAll)
    }
    
    func getTransactionLogDetail(transactionId: String) -> Single<BalanceLogDetail> {
        return transactionLogUseCase.getBalanceLogDetail(transactionId: transactionId)
    }
    
    func getSportsBookWagerDetail(wagerId: String) -> Single<HtmlString> {
        return transactionLogUseCase.getSportsBookWagerDetail(wagerId: wagerId)
    }
}
