import SwiftUI
import SharedBu

struct DepositCryptoRecordView<ViewModel>: View
    where ViewModel: DepositCryptoRecordViewModelProtocol & ObservableObject {
    
    let submitTransactionIdOnClick: ((SingleWrapper<HttpUrl>?) -> Void)?

    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ScrollView() {
            PageContainer {
                Header()
                Separator()
                Info(submitTransactionIdOnClick: submitTransactionIdOnClick)
                Separator()
            }
        }
        .pageBackgroundColor(.gray131313)
        .onViewDidLoad {
            viewModel.getDepositCryptoLog(transactionId: viewModel.transactionId)
        }
        .environmentObject(viewModel)
    }
    
}

extension DepositCryptoRecordView {
    
    enum Identifier: String {
        case headerCpsIncompleteHint
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
                    .localized(weight: .semibold, size: 24, color: .whitePure)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Localize.string("deposit_title")) - \(viewModel.header?.fromCryptoName ?? "")")
                        .localized(weight: .medium, size: 16, color: .whitePure)
                    
                    Text("\(Localize.string("common_cps_incomplete_field_placeholder_hint"))")
                        .localized(weight: .regular, size: 14, color: .gray9B9B9B)
                        .visibility(viewModel.header?.showInCompleteHint ?? true  ? .visible : .gone)
                        .id(DepositCryptoRecordView.Identifier.headerCpsIncompleteHint.rawValue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.bottom, 24)
            .onInspected(inspection, self)
        }
    }
    
    struct Info: View {
        typealias InfoRow = DepositCryptoRecordView.InfoRow
        typealias InfoTable = DepositCryptoRecordView.InfoTable
        typealias RemarkRow = DepositCryptoRecordView.RemarkRow
        
        @EnvironmentObject var viewModel: ViewModel
        
        var submitTransactionIdOnClick: ((SingleWrapper<HttpUrl>?) -> Void)?
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
            .padding(.bottom, 38)
            .onInspected(inspection, self)
        }
        
        private func generateInfoRow(_ records: [DepositCryptoRecord]) -> some View {
            ForEach(records.indices, id: \.self) { index in
                let record = records[index]
                switch record {
                case .info(let item):
                    InfoRow(item)
                case .link(let item):
                    InfoRow(item, clickAttachment: {
                        self.submitTransactionIdOnClick?(item.updateUrl)
                    })
                case .remark(let item):
                    RemarkRow(item)
                case .table(let requests, let finals):
                    InfoTable(applyInfo: requests, finallyInfo: finals)
                }
                
                Separator()
                    .visibility((index == records.count - 1) ? .gone : .visible)
            }
        }
    }
    
    struct InfoRow: View {
        let infoTitle: String
        let infoContent: String?
        let contentColor: UIColor
        let attachment: String?
        let clickAttachment: (() -> Void)?
        
        init(_ record: DepositCryptoRecord.Item?, clickAttachment: (() -> Void)? = nil) {
            self.infoTitle = record?.title ?? ""
            self.infoContent = record?.content
            self.contentColor = record?.contentColor ?? .whitePure
            self.attachment = record?.attachment
            self.clickAttachment = clickAttachment
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(infoTitle)
                    .localized(weight: .regular, size: 12, color: .gray9B9B9B)
                
                if let content = infoContent {
                    Text(content)
                        .localized(weight: .regular, size: 16, color: contentColor)
                        .id(DepositCryptoRecordView.Identifier.infoRowContent.rawValue)
                }
                
                if let attach = attachment {
                    Text(attach)
                        .underline(true, color: .from(.redF20000))
                        .localized(weight: .regular, size: 16, color: .redF20000)
                        .onTapGesture {
                            clickAttachment?()
                        }
                        .id(DepositCryptoRecordView.Identifier.infoRowAttachment.rawValue)
                }
            }
        }
    }
    
    struct InfoTable: View {
        let applyInfo: [DepositCryptoRecord.Item]?
        let finallyInfo: [DepositCryptoRecord.Item]?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if let applyInfo = applyInfo, let finallyInfo = finallyInfo {
                    LimitSpacer(8)
                    
                    ForEach(applyInfo.indices, id: \.self) {
                        if $0 == 0 {
                            Text(applyInfo[$0].title)
                                .localized(weight: .medium, size: 16, color: .gray9B9B9B)
                        }
                        else {
                            let record = applyInfo[$0]
                            DepositCryptoRecordView.InfoRow(record)
                        }
                    }
                    
                    Separator()
                    
                    ForEach(finallyInfo.indices, id: \.self) {
                        if $0 == 0 {
                            Text(finallyInfo[$0].title)
                                .localized(weight: .medium, size: 16, color: .gray9B9B9B)
                        }
                        else {
                            let record = finallyInfo[$0]
                            DepositCryptoRecordView.InfoRow(record)
                        }
                    }
                    
                    LimitSpacer(8)
                } else {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .strokeBorder(color: .gray9B9B9B, cornerRadius: 0)
            .id(DepositCryptoRecordView.Identifier.infoTable.rawValue)
        }
    }
    
    struct RemarkRow: View {
        let remarkTitle: String
        let remarkContent: [String]?
        let date: String?
        
        init(_ remark: DepositCryptoRecord.Remark?) {
            self.remarkTitle = remark?.title ?? ""
            self.remarkContent = remark?.content
            self.date = remark?.date
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(remarkTitle)
                    .localized(weight: .regular, size: 12, color: .gray9B9B9B)
                
                if let date = date, let content = remarkContent {
                    ForEach(content.indices, id: \.self) {
                        Text(date)
                            .localized(weight: .regular, size: 12, color: .gray9B9B9B)
                        LimitSpacer(2)
                        Text(content[$0])
                            .localized(weight: .regular, size: 16, color: .whitePure)
                        LimitSpacer(18)
                    }
                }
            }
            .id(DepositCryptoRecordView.Identifier.remarkRow.rawValue)
        }
    }
}



struct DepositCryptoRecordViewPreviews: PreviewProvider {
    
    class ViewModel: DepositCryptoRecordViewModelProtocol, ObservableObject {
        let transactionId: String = ""
        
        @Published private (set) var header: DepositCryptoRecordHeader?
        @Published private (set) var info: [DepositCryptoRecord]?
        
        init() {
            self.header = .init(fromCryptoName:"USDT", showInCompleteHint: true)
            
            self.info = [
                DepositCryptoRecord.info(
                    .init(title: Localize.string("balancelog_detail_id"),
                               content: "log._displayId")
                ),
                DepositCryptoRecord.info(
                    .init(title: Localize.string("activity_status"),
                               content: "log.statusString")
                ),
                DepositCryptoRecord.table(
                    [
                        .init(title:Localize.string("common_cps_apply_info")),
                        .init(title: Localize.string("common_cps_apply_crypto"),
                                   content: "processingMemo.requestFromCrypto"),
                        .init(title: Localize.string("common_cps_apply_rate"),
                                   content: "processingMemo.requestRate"),
                        .init(title: Localize.string("common_cps_apply_amount", "CNY"),
                                   content: "processingMemo.requestFiatFormat"),
                        .init(title: Localize.string("common_applytime"),
                                   content: "log.createDateTimeString")
                    ],
                    [
                        .init(title: Localize.string("common_cps_final_info")),
                        .init(title: Localize.string("common_cps_final_crypto"),
                                   content: "processingMemo.actualFromCrypto(isTransactionComplete)",
                                   contentColor: .orangeFF8000),
                        .init(title: Localize.string("common_cps_final_rate"),
                                   content: "processingMemo.actualRate(isTransactionComplete)"),
                        .init(title: Localize.string("common_cps_final_amount", "CNY"),
                                   content: "processingMemo.actualToFiatFormat(isTransactionComplete)"),
                        .init(title: Localize.string("common_cps_final_datetime"),
                                   content: "processingMemo.actualDateTimeString(isTransactionComplete)")
                    ]
                   ),
                DepositCryptoRecord.info(
                    .init(title: Localize.string("common_cps_remitter", Localize.string("common_player")),
                               content: "-")
                ),
                DepositCryptoRecord.info(
                    .init(title: Localize.string("common_cps_payee", Localize.string("cps_kto")),
                               content: "processingMemo.address")
                ),
                DepositCryptoRecord.info(
                    .init(title: Localize.string("common_cps_hash_id"),
                               content: "processingMemo._hashId")
                ),
                DepositCryptoRecord.remark(
                    .init(title: Localize.string("common_remark"),
                               content: ["1 > 2 > 3", "3 > 4 > 5"],
                               date: "log.updateTimeString")
                )
            ]
        }
        
        func getDepositCryptoLog(transactionId: String) { }
    }
    
    struct Preview: View {
        var viewModel = ViewModel()

        var body: some View {
            DepositCryptoRecordView(
                submitTransactionIdOnClick: nil,
                viewModel: viewModel
            )
        }
    }

    static var previews: some View {
        Preview()
    }
}
