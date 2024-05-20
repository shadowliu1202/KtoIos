import sharedbu
import SwiftUI

struct WithdrawalCryptoRecordDetailView<ViewModel>: View
    where ViewModel: WithdrawalCryptoRecordDetailViewModelProtocol & ObservableObject
{
    @StateObject var viewModel: ViewModel

    let displayId: String

    var body: some View {
        ScrollView(showsIndicators: false) {
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
            viewModel.getLog(displayId: displayId)
        }
        .environmentObject(viewModel)
    }
}

extension WithdrawalCryptoRecordDetailView {
    struct Header: View {
        @EnvironmentObject var viewModel: ViewModel

        var inspection = Inspection<Self>()

        var body: some View {
            VStack(alignment: .leading, spacing: 30) {
                Text(Localize.string("withdrawal_detail_title"))
                    .localized(weight: .semibold, size: 24, color: .greyScaleWhite)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Localize.string("withdrawal_title")) - \(viewModel.header?.fromCryptoName ?? "")")
                        .localized(weight: .medium, size: 16, color: .greyScaleWhite)

                    Text(Localize.string("common_cps_incomplete_field_placeholder_hint"))
                        .localized(weight: .regular, size: 14, color: .textPrimary)
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
                case .link(let item):
                    LinkRow(model: item)
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

struct WithdrawalCryptoDetailView_Previews: PreviewProvider {
    class ViewModel: WithdrawalCryptoRecordDetailViewModelProtocol, ObservableObject {
        private let date: Instant = .Companion().fromEpochMilliseconds(epochMilliseconds: 0)

        private lazy var data = generateCryptoLog(status: .approved)

        var header: CryptoRecordHeader?
        var info: [CryptoRecord]?

        init() {
            self.header = .init(fromCryptoName: "USDT", showUnCompleteHint: false)

            self.info = generateRecords(data)
        }

        func getLog(displayId _: String) { }

        private func generateCryptoLog(status: WithdrawalDto.LogStatus) -> WithdrawalDto.CryptoLog {
            let withdrawalDtoLog: WithdrawalDto.Log = .init(
                displayId: "Test123",
                amount: "100".toAccountCurrency(),
                createdDate: date,
                status: status,
                type: .crypto,
                isBankProcessing: false)

            let requestMemo = ExchangeMemo(
                fromCrypto: "100".toCryptoCurrency(supportCryptoType: .usdt),
                rate: CryptoExchangeFactory()
                    .create(
                        from: .usdt,
                        to: SupportLocale.China(),
                        exRate: "100"),
                toFiat: "100".toAccountCurrency(),
                date: date)

            let actualMemo = requestMemo

            let memo = WithdrawalDto.ProcessingMemo(
                request: status == .approved ? requestMemo : nil,
                actual: status == .approved ? actualMemo : nil,
                hashId: status == .approved ? "TestHashId" : "",
                fromWalletAddress: "remitter address",
                toWalletAddress: "payee address")

            let log: WithdrawalDto.CryptoLog = .init(
                log: withdrawalDtoLog,
                isTransactionComplete: true,
                approvedDate: date,
                updateHistories: ["level", "hihi"].map { generateHistory($0) },
                processingMemo: memo)

            return log
        }

        private func generateHistory(_ data: String) -> UpdateHistory {
            .init(
                createdDate: date,
                imageIds: [],
                remarkLevel1: "\(data)01",
                remarkLevel2: "\(data)02",
                remarkLevel3: "\(data)03")
        }
    }

    static var previews: some View {
        WithdrawalCryptoRecordDetailView(viewModel: ViewModel(), displayId: "")
    }
}
