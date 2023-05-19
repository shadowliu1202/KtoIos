import SwiftUI

extension WithdrawalCryptoLimitView {
  enum Identifier: String {
    case remainRequirementText
    case recordSectionTitle
    case recordCells
    case cellAmountText
  }
}

struct WithdrawalCryptoLimitView<ViewModel>: View
  where ViewModel:
  WithdrawalCryptoLimitViewModelProtocol &
  ObservableObject
{
  @StateObject private var viewModel: ViewModel

  init(viewModel: ViewModel) {
    self._viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(spacing: 24) {
          Header()

          VStack(spacing: 30) {
            RequirementSection()

            AchievedSection()
          }
        }
        .padding(.horizontal, 30)
      }
    }
    .onPageLoading(
      viewModel.summaryRequirement == nil ||
        viewModel.summaryRequirement == nil ||
        viewModel.summaryAchieved == nil)
    .environmentObject(viewModel)
    .pageBackgroundColor(.greyScaleDefault)
    .onViewDidLoad {
      viewModel.setupData()
    }
  }
}

extension WithdrawalCryptoLimitView {
  // MARK: - Header

  struct Header: View {
    @EnvironmentObject var viewModel: ViewModel

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(alignment: .leading, spacing: 30) {
        Text(Localize.string("cps_success_log"))
          .localized(weight: .semibold, size: 24, color: .greyScaleWhite)

        HighLightText(Localize.string("cps_remaining_requirement", viewModel.remainRequirement ?? ""))
          .highLight(viewModel.remainRequirement ?? "", with: .alert)
          .localized(weight: .semibold, size: 16, color: .textPrimary)
          .id(WithdrawalCryptoLimitView.Identifier.remainRequirementText.rawValue)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .onInspected(inspection, self)
    }
  }

  // MARK: - RequirementSection

  struct RequirementSection: View {
    @EnvironmentObject var viewModel: ViewModel

    var inspection = Inspection<Self>()

    var body: some View {
      VStack {
        if let summaryRequirement = viewModel.summaryRequirement {
          WithdrawalCryptoLimitView.recordSection(
            title: summaryRequirement.title,
            records: summaryRequirement.records)
        }
      }
      .onInspected(inspection, self)
    }
  }

  // MARK: - AchievedSection

  struct AchievedSection: View {
    @EnvironmentObject var viewModel: ViewModel

    var inspection = Inspection<Self>()

    var body: some View {
      VStack {
        if let summaryAchieved = viewModel.summaryAchieved {
          WithdrawalCryptoLimitView.recordSection(
            title: summaryAchieved.title,
            records: summaryAchieved.records)
        }
      }
      .onInspected(inspection, self)
    }
  }

  // MARK: - RecordSection

  static func recordSection(
    title: String,
    records: [WithdrawalCryptoLimitDataModel.Record])
    -> some View
  {
    VStack(spacing: 16) {
      Text(title)
        .localized(weight: .regular, size: 16, color: .textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .id(WithdrawalCryptoLimitView.Identifier.recordSectionTitle.rawValue)

      LazyVStack(spacing: 0) {
        ForEach(records) { record in
          recordCell(record)

          Separator()
            .visibility(
              record == records.last
                ? .gone
                : .visible)
        }
        .id(WithdrawalCryptoLimitView.Identifier.recordCells.rawValue)
      }
      .stroke(color: .textPrimary, cornerRadius: 1)
      .visibility(
        records.isEmpty
          ? .gone
          : .visible)
    }
  }

  // MARK: - recordCell

  static func recordCell(_ record: WithdrawalCryptoLimitDataModel.Record) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(record.dateTime)
        .localized(weight: .regular, size: 12, color: .textPrimary)

      Text(record.id)
        .localized(weight: .regular, size: 14, color: .textPrimary)

      Text(record.fiatAmount)
        .localized(weight: .regular, size: 14, color: .textPrimary)
        .id(WithdrawalCryptoLimitView.Identifier.cellAmountText.rawValue + "-" + record.id)

      Text(record.cryptoAmount)
        .localized(weight: .regular, size: 14, color: .greyScaleWhite)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
  }
}

struct WithdrawalCryptoLimitView_Previews: PreviewProvider {
  class FakeViewModel:
    WithdrawalCryptoLimitViewModelProtocol,
    ObservableObject
  {
    @Published var remainRequirement: String? = "10,628 CNY"

    @Published var summaryRequirement: WithdrawalCryptoLimitDataModel.Summary? = .init(
      title: "总虚拟币提现要求（上次清零后累计充值）：56,012 CNY",
      records: [
        .init(
          id: "DPBEQ-1234567882",
          dateTime: "2018/06/21 19:20:13",
          fiatAmount: "+10,999.00 CNY",
          cryptoAmount: "0.04907917 ETH"),
        .init(
          id: "DPBEQ-1234567884",
          dateTime: "2018/06/22 16:32:18",
          fiatAmount: "+10,999.00 CNY",
          cryptoAmount: "0.04907917 USDT"),
        .init(
          id: "DPBEQ-1234567886",
          dateTime: "2018/06/23 08:12:32",
          fiatAmount: "+10,999.00 CNY",
          cryptoAmount: "0.04907917 USDC"),
      ])

    @Published var summaryAchieved: WithdrawalCryptoLimitDataModel.Summary? = .init(
      title: "已完成虚拟币提现要求（上次清零后累计提现）：566.8768 CNY",
      records: [
        .init(
          id: "WDBEQ-1234567882",
          dateTime: "2018/06/21 19:20:13",
          fiatAmount: "+10,999.00 CNY",
          cryptoAmount: "0.04907917 ETH"),
        .init(
          id: "WDBEQ-1234567884",
          dateTime: "2018/06/22 16:32:18",
          fiatAmount: "+10,999.00 CNY",
          cryptoAmount: "0.04907917 USDT"),
        .init(
          id: "WDBEQ-1234567886",
          dateTime: "2018/06/23 08:12:32",
          fiatAmount: "+10,999.00 CNY",
          cryptoAmount: "0.04907917 USDC"),
      ])

    func setupData() { }
  }

  class FakeViewModel2:
    WithdrawalCryptoLimitViewModelProtocol,
    ObservableObject
  {
    @Published var remainRequirement: String? = nil
    @Published var summaryRequirement: WithdrawalCryptoLimitDataModel.Summary? = nil
    @Published var summaryAchieved: WithdrawalCryptoLimitDataModel.Summary? = nil

    func setupData() { }
  }

  static var previews: some View {
    WithdrawalCryptoLimitView(viewModel: FakeViewModel())
      .previewDisplayName("After Loading")

    WithdrawalCryptoLimitView(viewModel: FakeViewModel2())
      .previewDisplayName("On Loading")
  }
}
