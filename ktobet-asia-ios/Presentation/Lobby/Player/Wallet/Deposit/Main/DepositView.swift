import sharedbu
import SwiftUI

struct DepositView<ViewModel>: View
  where ViewModel: DepositViewModelProtocol & ObservableObject
{
  let playerConfig: PlayerConfiguration

  @StateObject var viewModel: ViewModel

  var onMethodSelected: ((DepositSelection) -> Void)?
  var onHistorySelected: ((PaymentLogDTO.Log) -> Void)?
  var onDisplayAll: (() -> Void)?

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(alignment: .leading, spacing: 30) {
          Payments(onSelected: onMethodSelected)
          Histories(onDisplayAll: onDisplayAll, onSelected: onHistorySelected)
        }
        .frame(maxWidth: .infinity)
      }
    }
    .onPageLoading(viewModel.recentLogs == nil || viewModel.selections == nil)
    .pageBackgroundColor(.greyScaleDefault)
    .environmentObject(viewModel)
    .environment(\.playerLocale, playerConfig.supportLocale)
    .onAppear {
      viewModel.setup()
    }
    .onDisappear {
      viewModel.resetSubscription()
    }
  }
}

// MARK: - Componment

extension DepositView {
  enum Identifier: String {
    case payments
    case paymentsEmptyReminder
    case histories
    case historiesEmptyReminder
    case historyShowAllButton
  }

  struct Payments: View {
    @EnvironmentObject var viewModel: ViewModel
    @Environment(\.playerLocale) var locale: SupportLocale

    var onSelected: ((DepositSelection) -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(spacing: 0) {
        if let selections = viewModel.selections {
          DepositView.PaymentHeader(isEmpty: selections.isEmpty)

          ForEach(selections.indices, id: \.self) {
            DepositView.PaymentRow(
              locale: locale,
              selection: selections[$0],
              onSelected: onSelected)

            Separator()
              .padding(.leading, 48)
              .visibility($0 == selections.count - 1 ? .invisible : .visible)
          }
          .backgroundColor(.greyScaleList)
          .id(DepositView.Identifier.payments.rawValue)

          DepositView.PaymentFooter(isEmpty: selections.isEmpty)
        }
        else {
          EmptyView()
        }
      }
      .onInspected(inspection, self)
    }
  }

  struct PaymentHeader: View {
    let isEmpty: Bool

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text(Localize.string("deposit_title_tips"))
          .localized(
            weight: .medium,
            size: 14,
            color: .textPrimary)
          .padding(.horizontal, 30)

        Separator()
          .visibility(isEmpty ? .gone : .visible)

        Text(Localize.string("deposit_no_available_type"))
          .localized(
            weight: .medium,
            size: 14,
            color: .greyScaleWhite)
          .id(DepositView.Identifier.paymentsEmptyReminder.rawValue)
          .padding(.horizontal, 30)
          .visibility(isEmpty ? .visible : .gone)
      }
    }
  }

  struct PaymentRow: View {
    let locale: SupportLocale
    let selection: DepositSelection

    var onSelected: ((DepositSelection) -> Void)?

    var body: some View {
      HStack(spacing: 0) {
        Image(selection.type?.imageName(locale: locale) ?? "Default(32)")
          .resizable()
          .frame(width: 32, height: 32)

        HStack(spacing: 4) {
          VStack(alignment: .leading, spacing: 4) {
            Text(selection.name)
              .localized(
                weight: .medium,
                size: 14,
                color: .greyScaleWhite)

            Text(selection.hint)
              .localized(
                weight: .regular,
                size: 12,
                color: .textPrimary)
              .multilineTextAlignment(.leading)
              .visibility(selection.hint.isEmpty ? .gone : .visible)
          }

          Spacer()

          Text(Localize.string("deposit_recommend"))
            .localized(
              weight: .semibold,
              size: 12,
              color: .greyScaleBlack)
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .backgroundColor(.complementaryDefault)
            .cornerRadius(12)
            .visibility(selection.isRecommend ? .visible : .gone)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)

        Image("iconChevronRight16")
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
      }
      .padding(.vertical, 18)
      .padding(.leading, 30)
      .padding(.trailing, 16)
      .contentShape(Rectangle())
      .onTapGesture {
        onSelected?(selection)
      }
    }
  }

  struct PaymentFooter: View {
    let isEmpty: Bool

    var body: some View {
      Separator()
        .visibility(isEmpty ? .gone : .visible)
    }
  }

  struct Histories: View {
    @EnvironmentObject var viewModel: ViewModel

    var onDisplayAll: (() -> Void)?
    var onSelected: ((PaymentLogDTO.Log) -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(spacing: 16) {
        if let recentLogs = viewModel.recentLogs {
          DepositView.HistoryHeader(
            isEmpty: recentLogs.isEmpty,
            onDisplayAll: onDisplayAll)

          if recentLogs.isEmpty {
            DepositView.HistoryNoRecords()
          }
          else {
            VStack(spacing: 0) {
              ForEach(recentLogs.indices, id: \.self) {
                let log = recentLogs[$0]

                RecentRecordRow(
                  date: log.createdDate.toDateTimeString(),
                  statusTitle: log.status.toLogString(),
                  statusColor: log.status.toLogColor(),
                  id: log.displayId,
                  amount: log.amount.formatString(),
                  isLastCell: $0 == recentLogs.endIndex)
                  .onTapGesture {
                    onSelected?(log)
                  }
              }
              .id(DepositView.Identifier.histories.rawValue)
            }
            .overlay(
              Separator(),
              alignment: .top)
            .overlay(
              Separator(),
              alignment: .bottom)
          }
        }
        else {
          EmptyView()
        }
      }
      .onInspected(inspection, self)
    }
  }

  struct HistoryHeader: View {
    let isEmpty: Bool

    var onDisplayAll: (() -> Void)?

    var body: some View {
      HStack(alignment: .bottom) {
        Text(Localize.string("deposit_log"))
          .localized(
            weight: .medium,
            size: 18,
            color: .textPrimary)

        Spacer()

        Button(
          action: { onDisplayAll?() },
          label: {
            Text(Localize.string("common_show_all"))
              .localized(
                weight: .medium,
                size: 14,
                color: .primaryDefault)
          })
          .visibility(isEmpty ? .gone : .visible)
          .id(DepositView.Identifier.historyShowAllButton.rawValue)
      }
      .padding(.horizontal, 30)
    }
  }

  struct HistoryNoRecords: View {
    var body: some View {
      HStack {
        Text(Localize.string("deposit_no_records"))
          .localized(
            weight: .medium,
            size: 14,
            color: .greyScaleWhite)
          .padding(.horizontal, 30)
          .id(DepositView.Identifier.historiesEmptyReminder.rawValue)

        Spacer()
      }
    }
  }
}

// MARK: - Preview

struct DepositView_Previews: PreviewProvider {
  class ViewModel:
    DepositViewModelProtocol,
    ObservableObject
  {
    @Published var recentLogs: [PaymentLogDTO.Log]?
    @Published var selections: [DepositSelection]?

    func setup() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        self.recentLogs = [.approved, .floating, .cancel, .fail]
          .enumerated()
          .map { index, value in
            PaymentLogDTO.Log(
              displayId: "TEST_" + "\(value.self)",
              currencyType: .fiat,
              status: value,
              amount: "\(100 + index)".toAccountCurrency(),
              createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
              updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0))
          }

        self.selections = [
          "\(DepositType.AlipayScan.rawValue)",
          "\(DepositType.WechatScan.rawValue)"
        ]
        .map {
          OnlinePayment(.init(
            identity: $0,
            name: "Test123",
            hint: "",
            isRecommend: true,
            beneficiaries: Single<NSArray>.just([]).asWrapper()))
        }
      }
    }
    
    func resetSubscription() { }
  }

  struct Preview: View {
    var body: some View {
      DepositView(
        playerConfig: PlayerConfigurationImpl(supportLocale: .China()),
        viewModel: ViewModel())
    }
  }

  static var previews: some View {
    VStack {
      Preview()
    }
  }
}
