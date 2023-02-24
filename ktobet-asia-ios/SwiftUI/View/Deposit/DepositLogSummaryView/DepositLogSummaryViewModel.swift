import Foundation
import RxDataSources
import RxSwift
import SharedBu

protocol DepositLogSummaryViewModelProtocol {
  typealias Section = SectionModel<String, PaymentLogDTO.Log>

  var totalAmount: String? { get }
  var sections: [Section]? { get }
  var dateType: DateType { get }
  var pagination: Pagination<PaymentLogDTO.GroupLog>! { get }
  var summaryRefreshTrigger: PublishSubject<Void> { get }

  func getCashLogSummary() -> Single<CurrencyUnit>
}

class DepositLogSummaryViewModel: CollectErrorViewModel,
  ObservableObject,
  Selecting,
  DepositLogSummaryViewModelProtocol
{
  typealias Section = DepositLogSummaryViewModelProtocol.Section

  private let filterStatusSource: [PaymentLogDTO.LogStatus] = [.approved, .reject, .pending, .floating]
  private let depositService: IDepositAppService
  private let disposeBag = DisposeBag()

  @Published private(set) var totalAmount: String?
  @Published private(set) var sections: [Section]?

  private(set) var pagination: Pagination<PaymentLogDTO.GroupLog>!
  private(set) var summaryRefreshTrigger = PublishSubject<Void>()

  @Published var selectedItems: [Selectable] = []

  var dateType: DateType = .week(
    fromDate: Date().adding(value: -6, byAdding: .day),
    toDate: Date())

  init(depositService: IDepositAppService) {
    self.depositService = depositService

    super.init()

    selectedItems = filterStatusSource

    pagination = .init(
      observable: { [unowned self] page in
        self.getDepositRecords(page: Int32(page))
      }, onElementChanged: { [unowned self] in
        self.sections = self.buildSections($0)
      })

    summaryRefreshTrigger
      .flatMapLatest { [unowned self] in
        self.getCashLogSummary()
      }
      .subscribe()
      .disposed(by: disposeBag)
  }

  func getCashLogSummary() -> Single<CurrencyUnit> {
    let beginDate = dateType.result.from.convertToKotlinx_datetimeLocalDate()
    let endDate = dateType.result.to.convertToKotlinx_datetimeLocalDate()

    return Single.from(
      depositService.getPaymentSummary(from: beginDate, to: endDate))
      .do(onSuccess: { [unowned self] in
        self.totalAmount = $0.formatString()
      })
      .compose(applySingleErrorHandler())
  }

  func buildSections(_ records: [PaymentLogDTO.GroupLog]) -> [Section] {
    Dictionary(grouping: records, by: { $0.groupDate.toDateString() })
      .map { dateString, groupLog -> Section in
        let today = Date().convertdateToUTC().toDateString()
        let sectionTitle = dateString == today ? Localize.string("common_today") : dateString

        return .init(model: sectionTitle, items: groupLog.flatMap { $0.logs })
      }
      .sorted(by: { $0.model > $1.model })
  }

  private func getDepositRecords(page: Int32 = 1) -> Observable<[PaymentLogDTO.GroupLog]> {
    let beginDate = dateType.result.from.convertToKotlinx_datetimeLocalDate()
    let endDate = dateType.result.to.convertToKotlinx_datetimeLocalDate()
    let statusSet: Set<PaymentLogDTO.LogStatus> = Set(selectedItems.filterThenCast())

    return Single.from(
      depositService.getPaymentLogs(
        filters: PaymentLogDTO.LogFilter(
          page: page,
          from: beginDate,
          to: endDate,
          filter: statusSet)))
      .map({ $0.compactMap { $0 as? PaymentLogDTO.GroupLog } })
      .do(onError: { [unowned self] in
        self.pagination.error.onNext($0)
      })
      .asObservable()
      .compose(applyObservableErrorHandle())
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
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
