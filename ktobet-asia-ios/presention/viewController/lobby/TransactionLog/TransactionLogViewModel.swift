import Foundation
import RxSwift
import RxDataSources
import SharedBu

protocol TransactionLogViewModelProtocol {
    typealias Section = SectionModel<String, TransactionLog>

    var summary: CashFlowSummary? { get }
    var sections: [Section]? { get }
    var dateType: DateType { get }
    
    var pagination: Pagination<Section>! { get }
    var summaryRefreshTrigger: PublishSubject<Void> { get }
    
    func searchTransactionLog() -> Observable<[Section]>
    func getCashFlowSummary() -> Single<CashFlowSummary>
}

class TransactionLogViewModel: CollectErrorViewModel,
                               ObservableObject,
                               TransactionLogViewModelProtocol {
    
    private let transactionLogUseCase: TransactionLogUseCase
    
    private let disposeBag = DisposeBag()
    
    private (set) var pagination: Pagination<TransactionLogViewModelProtocol.Section>!
    
    private (set) var summaryRefreshTrigger = PublishSubject<Void>()
    
    @Published private (set) var summary: CashFlowSummary?
    @Published private (set) var sections: [TransactionLogViewModelProtocol.Section]?
    
    var dateType: DateType = .week(
        fromDate: Date().adding(value: -7, byAdding: .day),
        toDate: Date()
    )
    
    var balanceLogFilterType: Int = 0
    
    init(transactionLogUseCase: TransactionLogUseCase) {
        self.transactionLogUseCase = transactionLogUseCase
        
        super.init()
        
        self.pagination = .init(
            observable: { [unowned self] _ in
                self.searchTransactionLog()
            }, onElementChanged: { [unowned self] in
                self.sections = $0
            }
        )
        
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
    
    func searchTransactionLog() -> Observable<[TransactionLogViewModelProtocol.Section]> {
        transactionLogUseCase
            .searchTransactionLog(
                from: dateType.result.from,
                to: dateType.result.to,
                BalanceLogFilterType: balanceLogFilterType,
                page: pagination.pageIndex
            )
            .map { [unowned self] in
                self.buildSections($0)
            }
            .do(onError: { [unowned self] in
                self.pagination.error.onNext($0)
            })
            .asObservable()
            .compose(applyObservableErrorHandle())
    }
    
    func getCashFlowSummary() -> Single<CashFlowSummary> {
        transactionLogUseCase
            .getCashFlowSummary(
                begin: dateType.result.from,
                end: dateType.result.to,
                balanceLogFilterType: balanceLogFilterType
            )
            .do(onSuccess: { [unowned self] in
                self.summary = $0
            })
            .compose(applySingleErrorHandler())
    }
    
    func getCashLogSummary(
        from: Date,
        to: Date
    ) -> Single<CashLogSummary> {

        transactionLogUseCase
            .getCashLogSummary(
                begin: from,
                end: to,
                balanceLogFilterType: TransactionLogPresenter.TransactionType.all.rawValue
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
    
    func buildSections(_ logs: [TransactionLog]) -> [TransactionLogViewModelProtocol.Section] {
        let sortedData = logs
            .sorted(by: { $0.date.toDateTimeFormatString() > $1.date.toDateTimeFormatString() })
        
        return Dictionary(
            grouping: sortedData,
            by: {
                String(format: "%02d/%02d/%02d", $0.date.year, $0.date.monthNumber, $0.date.dayOfMonth)
            }
        )
        .map { (key, value) -> TransactionLogViewModelProtocol.Section in
            let today = Date().convertdateToUTC().toDateString()
            let title = key == today ? Localize.string("common_today") : key
            
            return .init(
                model: title,
                items: value
            )
        }
        .sorted(by: { $0.model > $1.model })
    }
    
    func updateTypeFilter(
        with items: [FilterItem],
        and presenter: TransactionLogPresenter
    ) {
        guard let _items = items as? [TransactionLogPresenter.Item]
        else { fatalError("FilterItem should be TransactionLogPresenter.Item") }
        
        let type = presenter.getConditionStatus(_items)
        balanceLogFilterType = type.rawValue
    }
}
