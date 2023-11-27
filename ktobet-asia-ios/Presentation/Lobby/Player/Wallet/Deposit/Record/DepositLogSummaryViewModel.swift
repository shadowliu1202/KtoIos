import Foundation
import RxSwift
import sharedbu

protocol DepositLogSummaryViewModelProtocol {
  typealias Section = LogSections<PaymentLogDTO.Log>.Model

  var totalAmount: String? { get }
  var sections: [Section]? { get }
  var isPageLoading: Bool { get }
  var dateType: DateType { get }
  var pagination: Pagination<PaymentLogDTO.GroupLog>! { get }
  var summaryRefreshTrigger: PublishSubject<Void> { get }
}

class DepositLogSummaryViewModel:
  CollectErrorViewModel,
  ObservableObject,
  Selecting,
  DepositLogSummaryViewModelProtocol,
  LogSectionModelBuilder
{
  typealias Section = DepositLogSummaryViewModelProtocol.Section

  @Published private(set) var totalAmount: String?
  @Published private(set) var sections: [Section]?
  @Published private(set) var isPageLoading = false
  @Published var selectedItems: [Selectable] = []
  @Published var dateType: DateType = .week(
    fromDate: Date().adding(value: -6, byAdding: .day),
    toDate: Date())

  private let filterStatusSource: [PaymentLogDTO.LogStatus] = [.approved, .reject, .pending, .floating]
  private let depositService: IDepositAppService
  private let playerConfiguration: PlayerConfiguration

  private let disposeBag = DisposeBag()

  private(set) var pagination: Pagination<PaymentLogDTO.GroupLog>!
  private(set) var summaryRefreshTrigger = PublishSubject<Void>()

  init(
    depositService: IDepositAppService,
    playerConfig: PlayerConfiguration)
  {
    self.depositService = depositService
    self.playerConfiguration = playerConfig

    super.init()

    selectedItems = filterStatusSource

    pagination = .init(
      startIndex: 1,
      offset: 1,
      observable: { [unowned self] page in
        self.getRecords(page: Int32(page))
      },
      onLoading: { [unowned self] in
        self.isPageLoading = $0
      },
      onElementChanged: { [unowned self] element in
        self.sections = self.buildSections(element)
      })

    summaryRefreshTrigger
      .flatMapLatest { [unowned self] in
        self.getCashLogSummary()
      }
      .subscribe()
      .disposed(by: disposeBag)
  }

  func getCashLogSummary() -> Single<CurrencyUnit> {
    let beginDate = dateType.result.from.toLocalDate(playerConfiguration.localeTimeZone())
    let endDate = dateType.result.to.toLocalDate(playerConfiguration.localeTimeZone())

    return Single.from(
      depositService.getPaymentSummary(from: beginDate, to: endDate))
      .do(onSuccess: { [unowned self] in
        self.totalAmount = $0.formatString()
      })
      .compose(applySingleErrorHandler())
  }

  func buildSections(_ records: [PaymentLogDTO.GroupLog]) -> [Section] {
    regrouping(
      from: records,
      by: { $0.groupDate.toDateString() },
      converter: { $0.logs })
  }

  private func getRecords(page: Int32 = 1) -> Observable<[PaymentLogDTO.GroupLog]> {
    let beginDate = dateType.result.from.toLocalDate(playerConfiguration.localeTimeZone())
    let endDate = dateType.result.to.toLocalDate(playerConfiguration.localeTimeZone())
    let statusSet: Set<PaymentLogDTO.LogStatus> = Set(selectedItems.filterThenCast())

    return Single.from(
      depositService.getPaymentLogs(
        filters: PaymentLogDTO.LogFilter(
          page: page,
          from: beginDate,
          to: endDate,
          filter: statusSet)))
      .map {
        $0.compactMap { $0 as? PaymentLogDTO.GroupLog }
      }
      .do(onError: { [unowned self] in
        self.pagination.error.onNext($0)
      })
      .asObservable()
      .compose(applyObservableErrorHandle())
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}

// MARK: - Selecting

extension DepositLogSummaryViewModel {
  var dataSource: [Selectable] {
    filterStatusSource.map { $0 }
  }

  var selectedTitle: String {
    if isSelectedAll {
      return Localize.string("common_all")
    }
    else {
      return selectedItems
        .compactMap { $0 as? PaymentLogDTO.LogStatus }
        .reorder(by: filterStatusSource)
        .map { $0.title }
        .joined(separator: "/")
    }
  }
}

extension PaymentLogDTO.LogStatus: Selectable {
  var identity: String {
    title
  }

  var title: String {
    switch self {
    case .floating:
      return Localize.string("common_floating")
    case .pending:
      return Localize.string("common_processing")
    case .reject:
      return Localize.string("common_fail")
    case .approved:
      return Localize.string("common_success")
    default:
      return ""
    }
  }

  var image: String? {
    nil
  }
}

// MARK: - LogRowModel

extension PaymentLogDTO.Log: LogRowModel {
  var createdDateText: String {
    createdDate.toTimeString()
  }

  var statusConfig: (text: String, color: UIColor)? {
    (status.toLogString(), status.toLogColor())
  }

  var amountConfig: (text: String, color: UIColor) {
    (amount.formatString(), .textPrimary)
  }
}
