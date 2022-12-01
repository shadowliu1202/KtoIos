import SwiftUI
import SharedBu

struct DepositView: View {
    @Injected var playerConfig: PlayerConfiguration
    
    @StateObject var viewModel: DepositViewModel
    @StateObject var logViewModel: DepositLogViewModel
    
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
        .pageBackgroundColor(.gray131313)
        .environmentObject(viewModel)
        .environmentObject(logViewModel)
        .environment(\.playerLocale, playerConfig.supportLocale)
        .onAppear {
            viewModel.fetchMethods()
            logViewModel.fetchRecentLogs()
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
        @EnvironmentObject var viewModel: DepositViewModel
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
                            onSelected: onSelected
                        )
                        
                        Separator(color: .gray3C3E40)
                            .padding(.leading, 48)
                            .visibility($0 == selections.count - 1 ? .invisible : .visible)
                    }
                    .backgroundColor(.black1A1A1A)
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
                        color: .gray9B9B9B
                    )
                    .padding(.horizontal, 30)
                
                Separator(color: .gray3C3E40)
                    .visibility(isEmpty ? .gone : .visible)
                
                Text(Localize.string("deposit_no_available_type"))
                    .localized(
                        weight: .medium,
                        size: 14,
                        color: .whitePure
                    )
                    .padding(.horizontal, 30)
                    .visibility(isEmpty ? .visible : .gone)
                    .id(DepositView.Identifier.paymentsEmptyReminder.rawValue)
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
                                color: .whitePure
                            )

                        Text(selection.hint)
                            .localized(
                                weight: .regular,
                                size: 12,
                                color: .gray9B9B9B
                            )
                            .multilineTextAlignment(.leading)
                            .visibility(selection.hint.isEmpty ? .gone : .visible)
                    }
                        
                    Spacer()
                    
                    Text(Localize.string("deposit_recommend"))
                        .localized(
                            weight: .semibold,
                            size: 12,
                            color: .blackPure
                        )
                        .padding(.vertical, 4)
                        .padding(.horizontal, 9)
                        .backgroundColor(.yellowFFD500)
                        .cornerRadius(12)
                        .visibility(selection.isRecommend ? .visible : .gone)
                }
                .padding(.leading, 16)
                .padding(.trailing, 8)
                
                Image("Chevron Right Disable(24)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .padding(.vertical, 18)
            .padding(.leading, 30)
            .padding(.trailing, 16)
            .onTapGesture {
                onSelected?(selection)
            }
        }
    }
    
    struct PaymentFooter: View {
        let isEmpty: Bool
        
        var body: some View {
            Separator(color: .gray3C3E40)
                .visibility(isEmpty ? .gone : .visible)
        }
    }

    struct Histories: View {
        @EnvironmentObject var logViewModel: DepositLogViewModel
        
        var onDisplayAll: (() -> Void)?
        var onSelected: ((PaymentLogDTO.Log) -> Void)?
        
        var inspection = Inspection<Self>()
        
        var body: some View {
            VStack(spacing: 0) {
                if let recentLogs = logViewModel.recentLogs {
                    DepositView.HistoryHeader(
                        isEmpty: recentLogs.isEmpty,
                        onDisplayAll: onDisplayAll
                    )
                    
                    ForEach(recentLogs.indices, id: \.self) {
                        DepositView.HistoryRow(
                            log: recentLogs[$0],
                            onSelected: onSelected
                        )
                        
                        Separator(color: .gray3C3E40)
                            .padding(.top, 15)
                    }
                    .backgroundColor(.black1A1A1A)
                    .id(DepositView.Identifier.histories.rawValue)
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
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(Localize.string("deposit_log"))
                        .localized(
                            weight: .medium,
                            size: 18,
                            color: .gray9B9B9B
                        )
                    
                    Spacer()
                    
                    Button(
                        action: { onDisplayAll?() },
                        label: {
                            Text(Localize.string("common_show_all"))
                                .localized(
                                    weight: .medium,
                                    size: 14,
                                    color: .redF20000
                                )
                        }
                    )
                    .visibility(isEmpty ? .gone : .visible)
                    .id(DepositView.Identifier.historyShowAllButton.rawValue)
                }
                .padding(.horizontal, 30)
                
                Separator(color: .gray3C3E40)
                    .visibility(isEmpty ? .gone : .visible)
                
                Text(Localize.string("deposit_no_records"))
                    .localized(
                        weight: .medium,
                        size: 14,
                        color: .whitePure
                    )
                    .padding(.horizontal, 30)
                    .visibility(isEmpty ? .visible : .gone)
                    .id(DepositView.Identifier.historiesEmptyReminder.rawValue)
            }
        }
    }
    
    struct HistoryRow: View {
        let log: PaymentLogDTO.Log
        
        var onSelected: ((PaymentLogDTO.Log) -> Void)?
        
        var body: some View {
            VStack(spacing: 9) {
                HStack(alignment: .top) {
                    Text(log.createdDate.toDateTimeString())
                        .localized(
                            weight: .medium,
                            size: 12,
                            color: .gray9B9B9B
                        )
                    
                    Spacer()
                    
                    Text(log.status.toLogString())
                        .localized(
                            weight: .regular,
                            size: 14,
                            color: log.status.toLogColor()
                        )
                }
                
                HStack {
                    Text(log.displayId)
                        .localized(
                            weight: .medium,
                            size: 14,
                            color: .whitePure
                        )
                    
                    Spacer()
                    
                    Text(log.amount.formatString())
                        .localized(
                            weight: .regular,
                            size: 14,
                            color: .gray9B9B9B
                        )
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 15)
            .onTapGesture {
                onSelected?(log)
            }
        }
    }
}

// MARK: - Preview

struct DepositView_Previews: PreviewProvider {
    
    struct Preview: View {
        @Injected var viewModel: DepositViewModel
        @Injected var logViewModel: DepositLogViewModel
        
        let previewMethods: PaymentsDTO = .init(
            offline: nil,
            crypto: nil,
            fiat: [
                .init(
                    identity: "\(DepositType.AlipayScan.rawValue)",
                    name: "TestAli",
                    hint: "This is test.\nThis is test\nThis is test",
                    isRecommend: false,
                    beneficiaries: Single<NSArray>.just([]).asWrapper()
                ),
                .init(
                    identity: "\(DepositType.WechatScan.rawValue)",
                    name: "TestWechat",
                    hint: "",
                    isRecommend: true,
                    beneficiaries: Single<NSArray>.just([]).asWrapper()
                ),
            ],
            cryptoMarket: nil
        )
        
        let previewHistory: [PaymentLogDTO.Log] = {
            let status: [PaymentStatus] = [.approved, .floating, .cancel, .fail]
            
            return status
                .enumerated()
                .map { index, value in
                    PaymentLogDTO.Log(
                        displayId: "TEST_" + "\(value.self)",
                        currencyType: .fiat,
                        status: value,
                        amount: "\(100 + index)".toAccountCurrency(),
                        createdDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0),
                        updateDate: .Companion().fromEpochMilliseconds(epochMilliseconds: 0)
                    )
                }
        }()
        
        init() {
            viewModel.payments = .just(previewMethods)
            logViewModel.recentPaymentLogs = .just(previewHistory)
        }
        
        var body: some View {
            DepositView(
                viewModel: viewModel,
                logViewModel: logViewModel
            )
        }
    }
    
    static var previews: some View {
        Preview()
    }
}

