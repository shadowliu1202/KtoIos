import Foundation
import RxSwift
import SharedBu

protocol TransactionLogViewModelProtocol {
  typealias Section = LogSections<TransactionLog>.Model

  var summary: CashFlowSummary? { get }
  var sections: [Section]? { get }
  var isPageLoading: Bool { get }
  var dateType: DateType { get }

  var pagination: Pagination<TransactionLog>! { get }
  var summaryRefreshTrigger: PublishSubject<Void> { get }
  
  func getSupportLocale() -> SupportLocale
}

class TransactionLogViewModel:
  CollectErrorViewModel,
  ObservableObject,
  Selecting,
  TransactionLogViewModelProtocol,
  LogSectionModelBuilder
{
  @Published private(set) var summary: CashFlowSummary?
  @Published private(set) var sections: [TransactionLogViewModelProtocol.Section]?
  @Published private(set) var isPageLoading = false
  @Published var selectedItems: [Selectable] = []
  @Published var dateType: DateType = .week(
    fromDate: Date().adding(value: -6, byAdding: .day),
    toDate: Date())

  @Injected private var transactionLogUseCase: TransactionLogUseCase
  @Injected private var casinoMyBetAppService: ICasinoMyBetAppService
  @Injected private var p2pAppService: IP2PAppService
  @Injected private var playerConfig: PlayerConfiguration
  
  private let disposeBag = DisposeBag()

  private(set) var pagination: Pagination<TransactionLog>!
  private(set) var summaryRefreshTrigger = PublishSubject<Void>()

  var selectedLogType: Int {
    if isSelectedAll {
      return LogType.all.rawValue
    }

    let selected = selectedItems.first?.identity ?? ""
    return Int(selected) ?? LogType.all.rawValue
  }

  override init() {
    super.init()
    
    selectedItems = dataSource

    self.pagination = .init(
      startIndex: 1,
      offset: 1,
      observable: { [unowned self] currentIndex in
        self.searchTransactionLog(currentPage: currentIndex)
      },
      onLoading: { [unowned self] in
        self.isPageLoading = $0
      },
      onElementChanged: { [unowned self] element in
        self.sections = self.buildSections(element)
      })

    summaryRefreshTrigger
      .flatMapLatest { [unowned self] in
        self.getCashFlowSummary()
      }
      .subscribe()
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfig.supportLocale
  }
}

// MARK: - API

extension TransactionLogViewModel {
  func searchTransactionLog(currentPage: Int) -> Observable<[TransactionLog]> {
    transactionLogUseCase
      .searchTransactionLog(
        from: dateType.result.from,
        to: dateType.result.to,
        BalanceLogFilterType: selectedLogType,
        page: currentPage)
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
        balanceLogFilterType: selectedLogType)
      .do(onSuccess: { [unowned self] in
        self.summary = $0
      })
      .compose(applySingleErrorHandler())
  }

  func getCashLogSummary(
    from: Date,
    to: Date) -> Single<CashLogSummary>
  {
    transactionLogUseCase
      .getCashLogSummary(
        begin: from,
        end: to,
        balanceLogFilterType: LogType.all.rawValue)
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
  
  func getIsCasinoWagerDetailExist(by wagerID: String) async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
      Single.from(
        casinoMyBetAppService.getDetail(id: wagerID))
        .asCompletable()
        .observe(on: MainScheduler.instance)
        .subscribe(
          onCompleted: { continuation.resume(returning: true) },
          onError: {
            if $0 is HasNoWagerDetail {
              continuation.resume(returning: false)
            }
            else {
              continuation.resume(throwing: $0)
            }
          })
        .disposed(by: disposeBag)
    }
  }
  
  func getIsP2PWagerDetailExist(by wagerID: String) async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
      Observable.from(
        p2pAppService.getDetail(id: wagerID))
        .first()
        .asCompletable()
        .observe(on: MainScheduler.instance)
        .subscribe(
          onCompleted: { continuation.resume(returning: true) },
          onError: {
            if $0 is HasNoWagerDetail {
              continuation.resume(returning: false)
            }
            else {
              continuation.resume(throwing: $0)
            }
          })
        .disposed(by: disposeBag)
    }
  }
}

// MARK: - Data Handle

extension TransactionLogViewModel {
  func buildSections(_ logs: [TransactionLog]) -> [TransactionLogViewModelProtocol.Section] {
    regrouping(
      from: logs,
      by: {
        String(format: "%02d/%02d/%02d", $0.date.year, $0.date.monthNumber, $0.date.dayOfMonth)
      })
  }
}

// MARK: - Selecting

extension TransactionLogViewModel {
  var dataSource: [Selectable] {
    LogType.allCases.filter { $0 != .all }
  }

  var selectedTitle: String {
    isSelectedAll ? Localize.string("common_all") : selectedItems.first?.title ?? ""
  }
}

extension TransactionLogViewModel {
  enum LogType: Int, CaseIterable {
    case all = 0
    case deposit = 1
    case withdrawal = 2
    case sportsBook = 3
    case slot = 4
    case casino = 5
    case numberGame = 8
    case p2p = 9
    case arcade = 10
    case adjustment = 6
    case bonus = 7
  }
}

extension TransactionLogViewModel.LogType: Selectable {
  var identity: String { "\(rawValue)" }

  var title: String {
    switch self {
    case .all:
      return Localize.string("common_all")
    case .deposit:
      return Localize.string("common_deposit")
    case .withdrawal:
      return Localize.string("common_withdrawal")
    case .sportsBook:
      return Localize.string("common_sportsbook")
    case .slot:
      return Localize.string("common_slot")
    case .casino:
      return Localize.string("common_casino")
    case .numberGame:
      return Localize.string("common_keno")
    case .p2p:
      return Localize.string("common_p2p")
    case .arcade:
      return Localize.string("common_arcade")
    case .adjustment:
      return Localize.string("common_adjustment")
    case .bonus:
      return Localize.string("common_bonus")
    }
  }

  var image: String? { nil }
}

// MARK: - LogRowModel

extension TransactionLog: LogRowModel {
  var createdDateText: String {
    date.toTimeString()
  }

  var statusConfig: (text: String, color: UIColor)? { nil }

  var displayId: String { name }

  var amountConfig: (text: String, color: UIColor) {
    (amount.formatString(sign: .signed_), amount.isPositive ? .statusSuccess : .textPrimary)
  }
}
