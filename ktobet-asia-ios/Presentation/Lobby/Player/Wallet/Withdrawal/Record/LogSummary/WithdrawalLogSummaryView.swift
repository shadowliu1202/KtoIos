import sharedbu
import SwiftUI
import UIKit

struct WithdrawalLogSummaryView<ViewModel>: View
  where ViewModel:
  WithdrawalLogSummaryViewModelProtocol &
  Selecting &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  var dateFilterAction: DateFilter.Action?
  var onPresentFilterController: (() -> Void)?
  var onRowSelected: ((WithdrawalDto.Log) -> Void)?

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
        isLoading: viewModel.sections == nil,
        onBottomReached: {
          viewModel.pagination.loadNextPageTrigger.onNext(())
        })
        .environmentObject(viewModel)
        .onAppear {
          viewModel.pagination.refreshTrigger.onNext(())
        }
    }
  }
}

extension WithdrawalLogSummaryView {
  struct Header: View {
    @EnvironmentObject var viewModel: ViewModel

    var dateFilterAction: DateFilter.Action?
    var onPresentFilterController: (() -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      LogHeader(
        title: Localize.string("withdrawal_log"),
        currentDateType: viewModel.dateType,
        dateFilterAction: dateFilterAction,
        filterTitle: viewModel.selectedTitle,
        onPresentFilterController: onPresentFilterController)
        .onInspected(inspection, self)
    }
  }

  struct Sections: View {
    @EnvironmentObject var viewModel: ViewModel

    var onRowSelected: ((WithdrawalDto.Log) -> Void)?

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

struct WithdrawalLogView_Previews: PreviewProvider {
  class ViewModel: WithdrawalLogSummaryViewModelProtocol, ObservableObject, Selecting {
    var sections: [WithdrawalLogSummaryViewModelProtocol.Section]?
    var supportLocale: SupportLocale = .China()
    var isPageLoading = true
    var dateType: DateType = .week()
    var pagination: Pagination<WithdrawalDto.GroupLog>! = .init(startIndex: 0, offset: 0, observable: { _ in .just([]) })
    var dataSource: [Selectable] = []
    var selectedItems: [Selectable] = []
    var selectedTitle = "Test"

    init(isEmpty: Bool) {
      if !isEmpty {
        sections = [.init(
          title: "今天",
          items: (0...1).map { .init(
            displayId: "Test id \($0)",
            amount: "100".toAccountCurrency(),
            createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
            status: .approved,
            type: .fiat,
            isBankProcessing: false)
          })]
      }
      else { sections = [] }
    }
  }

  struct Preview: View {
    let isEmpty: Bool

    var body: some View {
      WithdrawalLogSummaryView(viewModel: ViewModel(isEmpty: isEmpty))
    }
  }

  static var previews: some View {
    Preview(isEmpty: false)

    Preview(isEmpty: true)
  }
}
