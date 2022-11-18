import Foundation
import RxSwift
import RxDataSources
import SharedBu

class TransactionLogViewModel: CollectErrorViewModel {
    typealias Section = SectionModel<String, TransactionLog>

    private let disposeBag = DisposeBag()
    
    private let summaryRelay = PublishSubject<CashFlowSummary>()
        
    private (set) var pagination: Pagination<Section>!
    
    private (set) var summaryRefreshTrigger = PublishSubject<()>()
    
    private var transactionLogUseCase: TransactionLogUseCase!
    
    var from: Date? = Date().adding(value: -7, byAdding: .day)
    var to: Date? = Date()
    
    var balanceLogFilterType: Int? = 0
    
    init(transactionLogUseCase: TransactionLogUseCase) {
        super.init()
        
        self.transactionLogUseCase = transactionLogUseCase
        
        pagination = .init(callBack: { [unowned self] page in
            self.searchTransactionLog(page: page)
                .map { self.buildSections($0) }
                .do(onError: {
                    self.pagination.error.onNext($0)
                })
        })
        
        summaryRefreshTrigger
            .flatMapLatest { [unowned self] in
                self.getCashFlowSummary()
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - API

extension TransactionLogViewModel {
    
    func searchTransactionLog(
        from: Date,
        to: Date,
        balanceLogFilterType: Int,
        page: Int
    ) -> Single<[TransactionLog]> {
        
        transactionLogUseCase
            .searchTransactionLog(
                from: from,
                to: to,
                BalanceLogFilterType: balanceLogFilterType,
                page: page
            )
            .compose(applySingleErrorHandler())
    }
    
    func searchTransactionLog(page: Int) -> Observable<[TransactionLog]> {
        guard let fromDate = from,
              let toDate = to,
              let filterType = balanceLogFilterType
        else {
            return Observable.error(KTOError.EmptyData)
        }
        
        return searchTransactionLog(
            from: fromDate,
            to: toDate,
            balanceLogFilterType: filterType, page: page
        )
        .asObservable()
    }
    
    func getCashFlowSummary() -> Single<CashFlowSummary> {
        guard let fromDate = from,
              let toDate = to,
              let filterType = balanceLogFilterType
        else {
            return Single.error(KTOError.EmptyData)
        }
        
        return transactionLogUseCase
            .getCashFlowSummary(
                begin: fromDate,
                end: toDate,
                balanceLogFilterType: filterType
            )
            .do(onSuccess: { [unowned self] in
                self.summaryRelay.onNext($0)
            })
            .compose(applySingleErrorHandler())
    }
    
    func getCashLogSummary() -> Single<CashLogSummary> {
        guard let fromDate = from,
              let toDate = to
        else { return Single.error(KTOError.EmptyData) }
        
        let filterAll = CashLogFilter.all.rawValue
        
        return transactionLogUseCase
            .getCashLogSummary(
                begin: fromDate,
                end: toDate,
                balanceLogFilterType: filterAll
            )
            .compose(applySingleErrorHandler())
    }
    
    func getTransactionLogDetail(transactionId: String) -> Single<BalanceLogDetail> {
        transactionLogUseCase
            .getBalanceLogDetail(transactionId: transactionId)
            .compose(applySingleErrorHandler())
    }
    
    func getSportsBookWagerDetail(wagerId: String) -> Single<HtmlString> {
        transactionLogUseCase
            .getSportsBookWagerDetail(wagerId: wagerId)
            .compose(applySingleErrorHandler())
    }
}

// MARK: - Data Handle

extension TransactionLogViewModel {
    
    var summary: Observable<CashFlowSummary> {
        summaryRelay.asObservable()
    }
    
    var sections: Observable<[Section]>{
        pagination.elements
            .skip(1)
            .catchAndReturn([])
            .asObservable()
    }
    
    func section(at index: Int) -> Section? {
        pagination.elements.value[index]
    }
    
    func buildSections(_ logs: [TransactionLog]) -> [Section] {
        let sortedData = logs
            .sorted(by: { $0.date.toDateTimeFormatString() > $1.date.toDateTimeFormatString() })
        
        return Dictionary(
            grouping: sortedData,
            by: {
                String(format: "%02d/%02d/%02d", $0.date.year, $0.date.monthNumber, $0.date.dayOfMonth)
            }
        )
        .map { (key, value) -> Section in
            let today = Date().convertdateToUTC().toDateString()
            let title = key == today ? Localize.string("common_today") : key
        
            return .init(
                model: title,
                items: value
            )
        }
        .sorted(by: { $0.model > $1.model })
    }
}
