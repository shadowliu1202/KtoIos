import RxSwift
import SharedBu
import SwiftUI
import UIKit

struct DepositLogSummaryView<ViewModel>: View
  where ViewModel:
  DepositLogSummaryViewModelProtocol &
  Selecting &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  var dateFilterAction: DateFilter.Action?
  var onPresentFilterController: (() -> Void)?
  var onRowSelected: ((PaymentLogDTO.Log) -> Void)?

  var body: some View {
    SafeAreaReader {
      LogSummary(
        header: {
          Header(
            dateFilterAction: dateFilterAction,
            onPresentFilterController: onPresentFilterController)
        },
        section: {
          Sections(onRowSelected: onRowSelected)
        },
        isResultEmpty: viewModel.sections.isNullOrEmpty(),
        isLoading: viewModel.sections == nil || viewModel.totalAmount == nil,
        onBottomReached: {
          viewModel.pagination.loadNextPageTrigger.onNext(())
        })
        .environmentObject(viewModel)
        .environment(\.playerLocale, viewModel.supportLocale)
        .onAppear {
          viewModel.pagination.refreshTrigger.onNext(())
          viewModel.summaryRefreshTrigger.onNext(())
        }
    }
  }
}

extension DepositLogSummaryView {
  enum Identifier {
    case summary
    case summaryAmount

    var rawValue: String { "\(self)" }
  }

  struct Header: View {
    @EnvironmentObject var viewModel: ViewModel

    var dateFilterAction: DateFilter.Action?
    var onPresentFilterController: (() -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      LogHeader(
        title: Localize.string("deposit_log"),
        currentDateType: viewModel.dateType,
        dateFilterAction: dateFilterAction,
        filterTitle: viewModel.selectedTitle,
        onPresentFilterController: onPresentFilterController,
        content: {
          HStack {
            Text(Localize.string("deposit_summary"))
              .localized(weight: .medium, size: 14, color: .greyScaleWhite)

            Spacer()

            Text(viewModel.totalAmount ?? "")
              .localized(weight: .medium, size: 14, color: .greyScaleWhite)
              .id(DepositLogSummaryView.Identifier.summaryAmount.rawValue)
          }
          .visibility(viewModel.totalAmount.isNullOrEmpty() ? .gone : .visible)
          .id(DepositLogSummaryView.Identifier.summary.rawValue)
        })
        .onInspected(inspection, self)
    }
  }

  struct Sections: View {
    @EnvironmentObject var viewModel: ViewModel

    var onRowSelected: ((PaymentLogDTO.Log) -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      LogSections(
        models: viewModel.sections,
        isPageLoading: viewModel.isPageLoading,
        onRowSelected: {
          onRowSelected?($0)
        })
        .onInspected(inspection, self)
    }
  }
}

struct DepositLogView_Previews: PreviewProvider {
  class ViewModel: DepositLogSummaryViewModelProtocol, ObservableObject, Selecting {
    @Published var selectedItems: [Selectable] = []

    var supportLocale: SupportLocale = .China()

    var pagination: Pagination<PaymentLogDTO.GroupLog>! = .init(startIndex: 0, offset: 0, observable: { _ in .just([]) })
    var summaryRefreshTrigger = PublishSubject<Void>()
    var totalAmount: String? = "1536"
    var dateType: DateType = .week()
    var sections: [DepositLogSummaryViewModelProtocol.Section]?
    var isPageLoading = true
    var dataSource: [Selectable] = []
    var selectedTitle = "Test"

    init(isEmpty: Bool) {
      if !isEmpty {
        sections = [
          .init(
            title: "今天",
            items: (0...1).map({
              PaymentLogDTO.Log(
                displayId: "TEST_A\($0)",
                currencyType: .fiat,
                status: PaymentStatus.floating,
                amount: "\($0 + 100)".toAccountCurrency(),
                createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
                updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0)) }))
        ]
      }
      else {
        sections = []
      }
    }
  }

  struct Preview: View {
    let isEmpty: Bool

    var body: some View {
      DepositLogSummaryView(viewModel: ViewModel(isEmpty: isEmpty))
    }
  }

  static var previews: some View {
    Preview(isEmpty: false)

    Preview(isEmpty: true)
  }
}
