import RxSwift
import SharedBu
import SwiftUI
import UIKit

struct TransactionLogView<ViewModel>: View
  where
  ViewModel: TransactionLogViewModelProtocol &
  Selecting &
  ObservableObject
{
  @StateObject var viewModel: ViewModel

  var dateFilterAction: DateFilter.Action?
  var onSummarySelected: (() -> Void)?
  var onRowSelected: ((TransactionLog) -> Void)?
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
          Sections(onRowSelected: onRowSelected)
        },
        isResultEmpty: viewModel.sections.isNullOrEmpty(),
        isLoading: viewModel.sections == nil || viewModel.summary == nil,
        onBottomReached: {
          viewModel.pagination.loadNextPageTrigger.onNext(())
        })
        .pageBackgroundColor(.greyScaleDefault)
        .environmentObject(viewModel)
        .environment(\.playerLocale, viewModel.supportLocale)
        .onViewDidLoad {
          viewModel.pagination.refreshTrigger.onNext(())
          viewModel.summaryRefreshTrigger.onNext(())
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
                "+" + (viewModel.summary?.income.formatString(.none) ?? "0.00"))
                .localized(
                  weight: .regular,
                  size: 14,
                  color: .statusSuccess)

              Text(
                "-" + (viewModel.summary?.outcome.formatString(.none) ?? "0.00"))
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

    var onRowSelected: ((TransactionLog) -> Void)?

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

// MARK: - Preview

struct TransactionLogView_Previews: PreviewProvider {
  class ViewModel: TransactionLogViewModelProtocol,
    Selecting,
    ObservableObject
  {
    var supportLocale: SupportLocale = .China()

    var summaryRefreshTrigger = PublishSubject<Void>()

    @Published var summary: CashFlowSummary? = .init(
      income: "1234".toAccountCurrency(),
      outcome: "123".toAccountCurrency())
    @Published var sections: [TransactionLogViewModelProtocol.Section]?
    @Published var selectedItems: [Selectable] = []

    var isPageLoading = true
    var dataSource: [Selectable] = []
    var selectedTitle = "Test"

    var dateType: DateType = .week()

    var pagination: Pagination<TransactionLog>! = .init(startIndex: 0, offset: 0, observable: { _ in .just([]) })

    init(isEmpty: Bool) {
      if isEmpty {
        sections = []
      }
      else {
        sections = [.init(
          title: "123456",
          items: (0...1).map {
            GeneralProduct(
              transactionLog: BalanceLogDetail(
                afterBalance: .zero(),
                amount: "\($0 + 100)".toAccountCurrency(),
                date: Date().convertToKotlinx_datetimeLocalDateTime(),
                wagerMappingId: "",
                productGroup: .P2P(supportProvider: .CompanionNone()),
                productType: .p2p,
                transactionType: .ProductBet(),
                remark: .None(),
                externalId: ""),
              displayName: .init(title: KNLazyCompanion().create(input: "Test only")))
          })]
      }
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
