import Differentiator
import RxSwift
import SharedBu
import SwiftUI
import UIKit

struct DepositLogSummaryView<ViewModel>: View
  where ViewModel: DepositLogSummaryViewModelProtocol & Selecting & ObservableObject
{
  let playerConfig: PlayerConfiguration

  @EnvironmentObject var safeAreaMonitor: SafeAreaMonitor
  @StateObject var viewModel: ViewModel

  var dateFilterAction: DateFilter.Action?
  var onPresentFilterController: (() -> Void)?
  var onRowSelected: ((PaymentLogDTO.Log) -> Void)?

  var body: some View {
    DelegatedScrollView {
      PageContainer {
        Header(
          dateFilterAction: dateFilterAction,
          onPresentFilterController: onPresentFilterController)

        Sections(onRowSelected: onRowSelected)
      }
      .if(viewModel.sections.isNullOrEmpty()) {
        $0.frame(height: safeAreaMonitor.safeAreaSize.height)
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 24)
    }
        onBottomReached: {
      viewModel.pagination.loadNextPageTrigger.onNext(())
    }
    .pageBackgroundColor(.gray131313)
    .environmentObject(viewModel)
    .environment(\.playerLocale, playerConfig.supportLocale)
    .onAppear {
      viewModel.pagination.refreshTrigger.onNext(())
      viewModel.summaryRefreshTrigger.onNext(())
    }
  }
}

extension DepositLogSummaryView {
  enum Identifier {
    case summary
    case summaryAmount
    case sectionHeader(at: Int)
    case section(at: Int)
    case emptyReminder

    var rawValue: String { "\(self)" }
  }

  struct Header: View {
    @EnvironmentObject var viewModel: ViewModel

    var dateFilterAction: DateFilter.Action?
    var onPresentFilterController: (() -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(alignment: .leading, spacing: 30) {
        Text(Localize.string("deposit_log"))
          .localized(weight: .semibold, size: 24, color: .whitePure)
          .padding(.leading, 6)

        VStack(spacing: 12) {
          DateFilter(
            currentType: viewModel.dateType,
            action: dateFilterAction)

          TypeFilter(
            title: viewModel.selectedTitle,
            onPresentController: onPresentFilterController)
            .padding(.bottom, 4)

          HStack {
            Text(Localize.string("deposit_summary"))
              .localized(weight: .medium, size: 14, color: .whitePure)

            Spacer()

            Text(viewModel.totalAmount ?? "")
              .localized(weight: .medium, size: 14, color: .whitePure)
              .id(DepositLogSummaryView.Identifier.summaryAmount.rawValue)
          }
          .visibility(viewModel.totalAmount.isNullOrEmpty() ? .gone : .visible)
          .id(DepositLogSummaryView.Identifier.summary.rawValue)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.bottom, 30)
      .onInspected(inspection, self)
    }
  }

  struct Sections: View {
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var safeAreaMonitor: SafeAreaMonitor

    var onRowSelected: ((PaymentLogDTO.Log) -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      if let sections = viewModel.sections {
        if !sections.isEmpty {
          //FIXME: workaround 
          VStack {
            ForEach(sections.indices, id: \.self) { sectionIndex in
              let section = sections[sectionIndex]
              Text(section.model)
                .localized(
                  weight: .medium,
                  size: 16,
                  color: .whitePure)
                .id(DepositLogSummaryView.Identifier.sectionHeader(at: sectionIndex).rawValue)
                .frame(maxWidth: .infinity, alignment: .leading)

              VStack(spacing: 8) {
                ForEach(section.items.indices, id: \.self) { rowIndex in
                  DepositLogSummaryView.Row(
                    log: section.items[rowIndex],
                    onSelected: onRowSelected)
                }
              }
              .padding(.bottom, 24)
              .id(DepositLogSummaryView.Identifier.section(at: sectionIndex).rawValue)
            }

            SwiftUIGradientArcView(lineWidth: 3)
              .visibility(viewModel.isPageLoading ? .visible : .gone)
              .frame(width: 24, height: 24)
          }
          .onInspected(inspection, self)
        }
        else {
          VStack(alignment: .center, spacing: 32) {
            Image("groupCopy")

            Text(Localize.string("common_no_record_temporarily"))
              .localized(
                weight: .regular,
                size: 14,
                color: .gray9B9B9B)
          }
          .frame(
            maxHeight: .infinity)
          .id(DepositLogSummaryView.Identifier.emptyReminder.rawValue)
          .onInspected(inspection, self)
        }
      }
      else {
        Spacer()
      }
    }
  }

  struct Row: View {
    let log: PaymentLogDTO.Log

    var onSelected: ((PaymentLogDTO.Log) -> Void)?

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .top) {
          Text(log.createdDate.toTimeString())
            .localized(
              weight: .medium,
              size: 12,
              color: .gray9B9B9B)

          Spacer()

          Text(log.status.toLogString())
            .localized(
              weight: .regular,
              size: 14,
              color: log.status.toLogColor())
        }

        HStack(alignment: .bottom) {
          Text(log.displayId)
            .localized(
              weight: .medium,
              size: 14,
              color: .whitePure)

          Spacer(minLength: 8)

          Text(log.amount.formatString())
            .localized(
              weight: .regular,
              size: 14,
              color: .gray9B9B9B)
        }
      }
      .padding(.vertical, 10)
      .padding(.horizontal, 12)
      .backgroundColor(.gray333333)
      .cornerRadius(8)
      .onTapGesture {
        onSelected?(log)
      }
    }
  }
}

struct DepositLogView_Previews: PreviewProvider {
  class ViewModel: DepositLogSummaryViewModelProtocol, ObservableObject, Selecting {
    @Published var selectedItems: [Selectable] = []

    var pagination: Pagination<PaymentLogDTO.GroupLog>!
    var summaryRefreshTrigger = PublishSubject<Void>()
    var totalAmount: String? = "1536"
    var dateType: DateType = .week()
    var sections: [DepositLogSummaryViewModelProtocol.Section]?
    var isPageLoading = true
    var dataSource: [Selectable] = []
    var selectedTitle = "Test"

    init(isEmpty: Bool) {
      pagination = Pagination<PaymentLogDTO.GroupLog>(
        observable: { _ in
          .just([])
        })

      if !isEmpty {
        sections = [
          .init(
            model: "今天",
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

    func getCashLogSummary() -> RxSwift.Single<CurrencyUnit> {
      .just("1536".toAccountCurrency())
    }

    func getDepositRecords(page _: Int32 = 1) -> Observable<[PaymentLogDTO.GroupLog]> {
      .never()
    }
  }

  struct Preview: View {
    let isEmpty: Bool

    var body: some View {
      SafeAreaReader {
        DepositLogSummaryView(
          playerConfig: PlayerConfigurationImpl(supportLocale: .China()),
          viewModel: ViewModel(isEmpty: isEmpty))
      }
    }
  }

  static var previews: some View {
    Preview(isEmpty: false)

    Preview(isEmpty: true)
  }
}
