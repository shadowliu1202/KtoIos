import Foundation
import RxSwift
import sharedbu

protocol TransactionLogViewModelProtocol {
  typealias Section = LogSections<TransactionDTO.Log>.Model

  var summary: CashFlowSummary? { get }
  var sections: [Section]? { get }
  var isPageLoading: Bool { get }
  var dateType: DateType { get }

  var pagination: Pagination<TransactionDTO.Log>! { get }
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

  private let transactionAppService: ITransactionAppService
  private let casinoMyBetAppService: ICasinoMyBetAppService
  private let p2pAppService: IP2PAppService
  private let playerConfig: PlayerConfiguration
  private let playerRepository: PlayerRepository
  
  private let disposeBag = DisposeBag()

  private(set) var pagination: Pagination<TransactionDTO.Log>!
  private(set) var summaryRefreshTrigger = PublishSubject<Void>()

  var selectedLogType: TransactionLogFilter_ {
    if isSelectedAll {
      return .all
    }

    let selected = selectedItems.first?.identity ?? ""
    return TransactionLogFilter_.values().get(index: Int32(selected) ?? 0) ?? .all
  }

  init(
    _ transactionAppService: ITransactionAppService,
    _ casinoMyBetAppService: ICasinoMyBetAppService,
    _ p2pAppService: IP2PAppService,
    _ playerConfig: PlayerConfiguration,
    _ playerRepository: PlayerRepository)
  {
    self.transactionAppService = transactionAppService
    self.casinoMyBetAppService = casinoMyBetAppService
    self.p2pAppService = p2pAppService
    self.playerConfig = playerConfig
    self.playerRepository = playerRepository
    
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
  
  func getSupportLocale() -> SupportLocale {
    playerConfig.supportLocale
  }
}

// MARK: - API

extension TransactionLogViewModel {
  func searchTransactionLog(currentPage: Int) -> Observable<[TransactionDTO.Log]> {
    Single.from(
      transactionAppService
        .getPageTransactionLogs(
          from: dateType.result.from.toLocalDate(playerConfig.localeTimeZone()),
          to: dateType.result.to.toLocalDate(playerConfig.localeTimeZone()),
          filter: selectedLogType,
          page: Int32(currentPage)))
      .map { $0.data as! [TransactionDTO.Log] }
      .do(onError: { [unowned self] in
        self.pagination.error.onNext($0)
      })
      .asObservable()
      .compose(applyObservableErrorHandle())
  }

  func getCashFlowSummary() -> Single<CashFlowSummary> {
    Single.from(
      transactionAppService.getCashFlowSummary(
        from: dateType.result.from.toLocalDate(playerConfig.localeTimeZone()),
        to: dateType.result.to.toLocalDate(playerConfig.localeTimeZone()),
        filter: selectedLogType))
      .do(onSuccess: { [unowned self] in
        self.summary = $0
      })
      .compose(applySingleErrorHandler())
  }

  func getCashLogSummary(
    from: Date,
    to: Date) -> Single<CashLogSummary>
  {
    Single.from(
      transactionAppService.getTransactionSummary(
        from: from.toLocalDate(playerConfig.localeTimeZone()),
        to: to.toLocalDate(playerConfig.localeTimeZone()),
        filter: selectedLogType))
      .compose(applySingleErrorHandler())
  }

  func getTransactionLogDetail(transactionId: String) -> Single<BalanceLogDetail> {
    Single.from(
      transactionAppService.getTransactionDetail(transactionId: transactionId))
      .compose(applySingleErrorHandler())
  }

  func getSportsBookWagerDetail(wagerId: String) -> Single<String> {
    playerRepository.getUtcOffset()
      .flatMap { [transactionAppService] in
        Single.from(transactionAppService.getSBKWagerDetail(
          wagerId: wagerId,
          zoneOffset: FixedOffsetTimeZone(offset: $0)))
      }
      .compose(applySingleErrorHandler())
      .map { $0 as String }
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
  func buildSections(_ logs: [TransactionDTO.Log]) -> [TransactionLogViewModelProtocol.Section] {
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

extension TransactionDTO.Log: LogRowModel {
  var createdDateText: String {
    date.toTimeString()
  }

  var statusConfig: (text: String, color: UIColor)? { nil }

  var displayId: String { title }

  var amountConfig: (text: String, color: UIColor) {
    (amount.formatString(sign: .signed_), amount.isPositive ? .statusSuccess : .textPrimary)
  }
}
