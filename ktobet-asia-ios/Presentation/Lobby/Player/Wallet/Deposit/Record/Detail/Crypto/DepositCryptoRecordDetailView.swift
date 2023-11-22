import sharedbu
import SwiftUI

struct DepositCryptoRecordDetailView<ViewModel>: View
  where ViewModel: DepositCryptoRecordDetailViewModelProtocol & ObservableObject
{
  let playerConfig: PlayerConfiguration
  let submitTransactionIdOnClick: ((SingleWrapper<HttpUrl>?) -> Void)?
  let transactionId: String

  @StateObject var viewModel: ViewModel

  var body: some View {
    ScrollView {
      PageContainer {
        Header()
        Separator()
        Info()
        Separator()
      }
    }
    .onPageLoading(viewModel.info == nil || viewModel.header == nil)
    .pageBackgroundColor(.greyScaleDefault)
    .onViewDidLoad {
      viewModel.getDepositCryptoLog(
        transactionId: transactionId,
        submitTransactionIdOnClick: submitTransactionIdOnClick)
    }
    .environmentObject(viewModel)
    .environment(\.playerLocale, playerConfig.supportLocale)
  }
}

extension DepositCryptoRecordDetailView {
  enum Identifier: String {
    case headerCpsUnCompleteHint
    case infoTable
    case remarkRow
    case infoRowContent
    case infoRowAttachment
  }

  struct Header: View {
    @EnvironmentObject var viewModel: ViewModel

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(alignment: .leading, spacing: 30) {
        Text(Localize.string("deposit_detail_title"))
          .localized(weight: .semibold, size: 24, color: .greyScaleWhite)

        VStack(alignment: .leading, spacing: 8) {
          Text("\(Localize.string("deposit_title")) - \(viewModel.header?.fromCryptoName ?? "")")
            .localized(weight: .medium, size: 16, color: .greyScaleWhite)

          Text(Localize.string("common_cps_incomplete_field_placeholder_hint"))
            .localized(weight: .regular, size: 14, color: .textPrimary)
            .id(DepositCryptoRecordDetailView.Identifier.headerCpsUnCompleteHint.rawValue)
            .visibility(viewModel.header?.showUnCompleteHint ?? true ? .visible : .gone)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 30)
      .padding(.bottom, 24)
      .onInspected(inspection, self)
    }
  }

  struct Info: View {
    @EnvironmentObject var viewModel: ViewModel

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        if let records = viewModel.info {
          generateInfoRow(records)
        }
        else {
          EmptyView()
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 30)
      .padding(.top, 8)
      .padding(.bottom, 56)
      .onInspected(inspection, self)
    }

    private func generateInfoRow(_ records: [CryptoRecord]) -> some View {
      ForEach(records.indices, id: \.self) { index in
        let record = records[index]
        switch record {
        case .info(let item):
          DefaultRow(model: item)
            .id(DepositCryptoRecordDetailView.Identifier.infoRowContent.rawValue)
        case .link(let item):
          LinkRow(model: item)
            .id(DepositCryptoRecordDetailView.Identifier.infoRowAttachment.rawValue)
        case .remark(let item):
          RemarkRow(model: item)
        case .table(let requests, let finals):
          LimitSpacer(0)
          InfoTable(
            applyInfo: requests,
            finallyInfo: finals)
          LimitSpacer(0)
        }

        Separator()
          .visibility((index == records.count - 1) ? .gone : .visible)
      }
    }
  }
}

struct DepositCryptoRecordViewPreviews: PreviewProvider {
  class ViewModel: DepositCryptoRecordDetailViewModelProtocol, ObservableObject {
    let transactionId = ""

    @Published private(set) var header: CryptoRecordHeader?
    @Published private(set) var info: [CryptoRecord]?

    init() {
      self.header = .init(fromCryptoName: "USDT", showUnCompleteHint: true)

      self.info = [
        .info(
          .init(
            title: Localize.string("balancelog_detail_id"),
            content: "log._displayId")),
        .info(
          .init(
            title: Localize.string("activity_status"),
            content: "log.statusString")),
        .table(
          [
            .init(title: Localize.string("common_cps_apply_info")),
            .init(
              title: Localize.string("common_cps_apply_crypto"),
              content: "processingMemo.requestFromCrypto"),
            .init(
              title: Localize.string("common_cps_apply_rate"),
              content: "processingMemo.requestRate"),
            .init(
              title: Localize.string("common_cps_apply_amount", "CNY"),
              content: "processingMemo.requestFiatFormat"),
            .init(
              title: Localize.string("common_applytime"),
              content: "log.createDateTimeString")
          ],
          [
            .init(title: Localize.string("common_cps_final_info")),
            .init(
              title: Localize.string("common_cps_final_crypto"),
              content: "processingMemo.actualFromCrypto(isTransactionComplete)",
              contentColor: .alert),
            .init(
              title: Localize.string("common_cps_final_rate"),
              content: "processingMemo.actualRate(isTransactionComplete)"),
            .init(
              title: Localize.string("common_cps_final_amount", "CNY"),
              content: "processingMemo.actualToFiatFormat(isTransactionComplete)"),
            .init(
              title: Localize.string("common_cps_final_datetime"),
              content: "processingMemo.actualDateTimeString(isTransactionComplete)")
          ]),
        .info(
          .init(
            title: Localize.string("common_cps_remitter", Localize.string("common_player")),
            content: "-")),
        .info(
          .init(
            title: Localize.string("common_cps_payee", Localize.string("cps_kto")),
            content: "processingMemo.address")),
        .info(
          .init(
            title: Localize.string("common_cps_hash_id"),
            content: "processingMemo._hashId")),
        .remark(
          .init(
            title: Localize.string("common_remark"),
            content: ["1 > 2 > 3", "3 > 4 > 5"],
            date: ["date1", "date2"]))
      ]
    }

    func getDepositCryptoLog(
      transactionId _: String,
      submitTransactionIdOnClick _: ((SingleWrapper<HttpUrl>?) -> Void)?) { }
  }

  struct Preview: View {
    var viewModel = ViewModel()

    var body: some View {
      DepositCryptoRecordDetailView(
        playerConfig: PlayerConfigurationImpl(supportLocale: .China()),
        submitTransactionIdOnClick: nil,
        transactionId: "123",
        viewModel: viewModel)
    }
  }

  static var previews: some View {
    Preview()
  }
}
