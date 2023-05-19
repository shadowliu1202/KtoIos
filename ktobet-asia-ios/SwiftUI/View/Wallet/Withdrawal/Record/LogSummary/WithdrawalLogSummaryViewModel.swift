import Foundation
import RxSwift
import SharedBu

protocol WithdrawalLogSummaryViewModelProtocol {
  typealias Section = LogSections<WithdrawalDto.Log>.Model

  var supportLocale: SupportLocale { get }
  var sections: [Section]? { get }
  var isPageLoading: Bool { get }
  var dateType: DateType { get }
  var pagination: Pagination<WithdrawalDto.GroupLog>! { get }
}

class WithdrawalLogSummaryViewModel:
  CollectErrorViewModel,
  ObservableObject,
  Selecting,
  WithdrawalLogSummaryViewModelProtocol,
  LogSectionModelBuilder
{
  typealias Section = WithdrawalLogSummaryViewModelProtocol.Section

  @Published private(set) var sections: [Section]?
  @Published private(set) var isPageLoading = false
  @Published var selectedItems: [Selectable] = []
  @Published var dateType: DateType = .week(
    fromDate: Date().adding(value: -6, byAdding: .day),
    toDate: Date())

  private let filterStatusSource: [WithdrawalDto.LogFilterStatus] = [.approved, .reject, .pending, .floating, .canceled]
  private let withdrawalService: IWithdrawalAppService
  private let disposeBag = DisposeBag()

  private(set) var pagination: Pagination<WithdrawalDto.GroupLog>!
  private(set) var summaryRefreshTrigger = PublishSubject<Void>()

  let supportLocale: SupportLocale

  init(
    withdrawalService: IWithdrawalAppService,
    playerConfig: PlayerConfiguration)
  {
    self.withdrawalService = withdrawalService
    self.supportLocale = playerConfig.supportLocale

    super.init()

    selectedItems = filterStatusSource

    pagination = .init(
      observable: { [unowned self] page in
        self.getRecords(page: Int32(page))
      },
      onLoading: { [unowned self] in
        self.isPageLoading = $0
      },
      onElementChanged: { [weak self] element in
        guard let self else { return }
        DispatchQueue.main.async {
          self.sections = self.buildSections(element)
        }
      })
  }

  func buildSections(_ records: [WithdrawalDto.GroupLog]) -> [Section] {
    regrouping(
      from: records,
      by: { $0.groupDate.toDateString() },
      converter: { $0.logs })
  }

  private func getRecords(page: Int32 = 1) -> Observable<[WithdrawalDto.GroupLog]> {
    let beginDate = dateType.result.from.convertToKotlinx_datetimeLocalDate()
    let endDate = dateType.result.to.convertToKotlinx_datetimeLocalDate()
    let statusSet: Set<WithdrawalDto.LogFilterStatus> = Set(selectedItems.filterThenCast())

    return Single.from(
      withdrawalService.getLogs(
        filter: .init(
          from: beginDate,
          to: endDate,
          statusFilter: statusSet),
        page: page))
      .map {
        $0.compactMap { $0 as? WithdrawalDto.GroupLog }
      }
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

extension WithdrawalLogSummaryViewModel {
  var dataSource: [Selectable] {
    filterStatusSource.map { $0 }
  }

  var selectedTitle: String {
    if isSelectedAll {
      return Localize.string("common_all")
    }
    else {
      return selectedItems
        .compactMap { $0 as? WithdrawalDto.LogFilterStatus }
        .reorder(by: filterStatusSource)
        .map { $0.title }
        .joined(separator: "/")
    }
  }
}

extension WithdrawalDto.LogFilterStatus: Selectable {
  var identity: String { title }

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
    case .canceled:
      return Localize.string("common_cancel")
    default:
      return ""
    }
  }

  var image: String? { nil }
}

// MARK: - LogRowModel

extension WithdrawalDto.Log: LogRowModel {
  var paymentStatus: PaymentStatus {
    switch self.status {
    case .pending:
      return .pending
    case .floating:
      return .floating
    case .approved:
      return .approved
    case .cancel:
      return .cancel
    case .fail:
      return .fail
    default:
      return .fail
    }
  }

  var createdDateText: String {
    createdDate.toTimeString()
  }

  var statusConfig: (text: String, color: UIColor)? {
    (paymentStatus.toLogString(), paymentStatus.toLogColor())
  }

  var amountConfig: (text: String, color: UIColor) {
    (amount.formatString(), .textPrimary)
  }
}
