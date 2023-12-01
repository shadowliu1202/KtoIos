import Combine
import RxSwift
import sharedbu
import SwiftUI
import UIKit

struct TransactionLogView<ViewModel>: View
  where
  ViewModel: TransactionLogViewModelProtocol &
  Selecting &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  private let selectedLogSubject = PassthroughSubject<TransactionDTO.Log, Never>()
  
  var dateFilterAction: DateFilter.Action?
  var onSummarySelected: (() -> Void)?
  var onRowSelected: ((TransactionDTO.Log) -> Void)?
  var onPresentFilterController: (() -> Void)?

  var body: some View {
    SafeAreaReader {
      LogSummary(
        header: {
          Header(
            dateFilterAction: dateFilterAction,
            onSummarySelected: onSummarySelected,
            onPresentFilterController: onPresentFilterController)
        },
        section: {
          Sections(selectedLogSubject)
        },
        isResultEmpty: viewModel.sections.isNullOrEmpty(),
        isLoading: viewModel.sections == nil || viewModel.summary == nil,
        onBottomReached: {
          viewModel.pagination.loadNextPageTrigger.onNext(())
        })
        .pageBackgroundColor(.greyScaleDefault)
        .environmentObject(viewModel)
        .environment(\.playerLocale, viewModel.getSupportLocale())
        .onViewDidLoad {
          viewModel.pagination.refreshTrigger.onNext(())
          viewModel.summaryRefreshTrigger.onNext(())
        }
        .onReceive(
          selectedLogSubject
            .throttle(for: .milliseconds(300), scheduler: DispatchQueue.main, latest: false))
      {
        onRowSelected?($0)
      }
    }
  }
}

// MARK: - Component

extension TransactionLogView {
  struct Summary: View {
    @EnvironmentObject var viewModel: ViewModel

    var onSelected: (() -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      FunctionalButton(
        imageName: "iconSummary24",
        content: {
          HStack {
            Text(Localize.string("common_transactionsummary"))
              .localized(
                weight: .medium,
                size: 14,
                color: .textPrimary)

            Spacer()

            VStack(alignment: .trailing) {
              Text(
                "+" + (viewModel.summary?.income.abs().formatString() ?? "0.00"))
                .localized(
                  weight: .regular,
                  size: 14,
                  color: .statusSuccess)

              Text(
                "-" + (viewModel.summary?.outcome.abs().formatString() ?? "0.00"))
                .localized(
                  weight: .regular,
                  size: 14,
                  color: .textPrimary)
            }
          }
        },
        borderPadding: 8,
        action: {
          onSelected?()
        })
        .onInspected(inspection, self)
    }
  }

  struct Header: View {
    @EnvironmentObject var viewModel: ViewModel

    var dateFilterAction: DateFilter.Action?
    var onSummarySelected: (() -> Void)?
    var onPresentFilterController: (() -> Void)?

    var body: some View {
      VStack(spacing: 12) {
        HStack(spacing: 9) {
          DateFilter(
            currentType: viewModel.dateType,
            action: dateFilterAction)

          TypeFilter(
            title: viewModel.selectedTitle,
            onPresentController: onPresentFilterController)
        }

        TransactionLogView.Summary(onSelected: onSummarySelected)
      }
    }
  }

  struct Sections: View {
    @EnvironmentObject var viewModel: ViewModel

    private let selectedLogSubject: PassthroughSubject<TransactionDTO.Log, Never>

    var inspection = Inspection<Self>()

    init(
      _ selectedLogSubject: PassthroughSubject<TransactionDTO.Log, Never>)
    {
      self.selectedLogSubject = selectedLogSubject
    }
    
    var body: some View {
      LogSections(
        models: viewModel.sections,
        isPageLoading: viewModel.isPageLoading,
        onRowSelected: {
          selectedLogSubject.send($0)
        })
        .onInspected(inspection, self)
    }
  }
}

// MARK: - Preview

struct TransactionLogView_Previews: PreviewProvider {
  class ViewModel: TransactionLogViewModelProtocol,
    Selecting,
    ObservableObject
  {
    var summaryRefreshTrigger = PublishSubject<Void>()

    @Published var summary: CashFlowSummary? = .init(
      income: "1234".toAccountCurrency(),
      outcome: "123".toAccountCurrency())
    @Published var sections: [TransactionLogViewModelProtocol.Section]?
    @Published var selectedItems: [Selectable] = []

    var isPageLoading = true
    var isDecidingNavigation = false
    var dataSource: [Selectable] = []
    var selectedTitle = "Test"

    var dateType: DateType = .week()

    var pagination: Pagination<TransactionDTO.Log>! = .init(startIndex: 0, offset: 0, observable: { _ in .just([]) })

    init(isEmpty: Bool) {
      if isEmpty {
        sections = []
      }
      else {
        sections = [.init(
          title: "123456",
          items: (0...1).map {
            TransactionDTO.Log(
              id: "1",
              type: .p2p,
              amount: "\($0 + 100)".toAccountCurrency(),
              date: Date().toLocalDateTime(.current),
              title: "Test only",
              detailId: "",
              detailOption: .P2P(isUnknownDetail: true))
          })]
      }
    }
    
    func getSupportLocale() -> SupportLocale {
      .China()
    }
  }

  struct Preview: View {
    let isEmpty: Bool

    var body: some View {
      TransactionLogView(viewModel: ViewModel(isEmpty: isEmpty))
    }
  }

  static var previews: some View {
    SafeAreaReader {
      Preview(isEmpty: true)
    }

    SafeAreaReader {
      Preview(isEmpty: false)
    }
  }
}
