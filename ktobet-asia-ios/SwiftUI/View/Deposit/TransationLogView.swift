import SwiftUI
import UIKit
import RxSwift
import SharedBu

struct TransactionLogView<ViewModel>: View
where
    ViewModel: TransactionLogViewModelProtocol &
               Selecting &
               ObservableObject
{
    @EnvironmentObject var safeAreaMonitor: SafeAreaMonitor

    @StateObject var viewModel: ViewModel

    let playerConfig: PlayerConfiguration
    
    var onDateSelected: DateFilter.Selection?
    var onSummarySelected: (() -> Void)?
    var onRowSelected: ((TransactionLog) -> Void)?
    var onNavigateToFilterController: (() -> Void)?
    
    var body: some View {
        DelegatedScrollView {
            PageContainer {
                Header(
                    onDateSelected: onDateSelected,
                    onSummarySelected: onSummarySelected,
                    onNavigateToFilterController: onNavigateToFilterController
                )
                
                LimitSpacer(30)
                    .visibility(viewModel.sections.isNullOrEmpty() ? .gone : .visible)
                
                Sections(onRowSelected: onRowSelected)
            }
            .if(viewModel.sections.isNullOrEmpty()) {
                $0.frame(height: safeAreaMonitor.safeAreaSize.height)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            
        } onBottomReached: {
            viewModel.pagination.loadNextPageTrigger.onNext(())
        }
        .pageBackgroundColor(.gray131313)
        .environmentObject(viewModel)
        .environment(\.playerLocale, playerConfig.supportLocale)
        .onViewDidLoad {
            viewModel.pagination.refreshTrigger.onNext(())
            viewModel.summaryRefreshTrigger.onNext(())
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
                                color: .gray9B9B9B
                            )
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(
                                viewModel
                                    .summary?
                                    .income
                                    .formatString(sign: .signed_) ?? "0.00"
                            )
                            .localized(
                                weight: .regular,
                                size: 14,
                                color: .green6AB336
                            )
                            
                            Text(
                                viewModel
                                    .summary?
                                    .outcome
                                    .formatString(sign: .signed_) ?? "0.00"
                            )
                            .localized(
                                weight: .regular,
                                size: 14,
                                color: .gray9B9B9B
                            )
                        }
                    }
                },
                action: {
                    onSelected?()
                }
            )
            .onInspected(inspection, self)
        }
    }
    
    struct Header: View {
        weak var parentViewController: UIViewController?
        
        @EnvironmentObject var viewModel: ViewModel
        
        var onDateSelected: DateFilter.Selection?
        var onSummarySelected: (() -> Void)?
        var onNavigateToFilterController: (() -> Void)?

        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 9) {
                    DateFilter(
                        currentType: viewModel.dateType,
                        onDateSelected: onDateSelected
                    )
                    
                    TypeFilter(
                        title: viewModel.selectedTitle,
                        onNavigateToController: onNavigateToFilterController
                    )
                }
                
                TransactionLogView.Summary(
                    onSelected: onSummarySelected
                )
            }
        }
    }
    
    struct Row: View {
        let log: TransactionLog
        
        var onSelected: ((TransactionLog) -> Void)?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(log.date.toTimeString())
                    .localized(
                        weight: .medium,
                        size: 12,
                        color: .gray9B9B9B
                    )
                
                HStack(alignment: .bottom) {
                    Text(log.name)
                        .localized(
                            weight: .medium,
                            size: 14,
                            color: .whitePure
                        )
                    
                    Spacer(minLength: 8)
                    
                    Text(log.amount.formatString(sign: .signed_))
                        .localized(
                            weight: .regular,
                            size: 14,
                            color: log.amount.isPositive ? .green6AB336 : .gray9B9B9B
                        )
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
    
    struct Sections: View {
        @EnvironmentObject var viewModel: ViewModel
        @EnvironmentObject var safeAreaMonitor: SafeAreaMonitor
        
        var onRowSelected: ((TransactionLog) -> Void)?
        
        var inspection = Inspection<Self>()
        
        var body: some View {
            if let sections = viewModel.sections {
                if !sections.isEmpty {
                    LazyVStack(alignment: .leading) {
                        ForEach(sections.indices, id: \.self) { sectionIndex in
                            let section = sections[sectionIndex]
                            Text(section.model)
                                .localized(
                                    weight: .medium,
                                    size: 16,
                                    color: .whitePure
                                )
                            
                            VStack(spacing: 8) {
                                ForEach(section.items.indices, id: \.self) { rowIndex in
                                    TransactionLogView.Row(
                                        log: section.items[rowIndex],
                                        onSelected: onRowSelected
                                    )
                                }
                            }
                            .padding(.bottom, 24)
                        }
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
                                color: .gray9B9B9B
                            )
                    }
                    .frame(
                        maxHeight: .infinity
                    )
                    .onInspected(inspection, self)
                }
            }
            else {
                Spacer()
            }
        }
    }
}

// MARK: - Preview

struct TransactionLogView_Previews: PreviewProvider {
    
    class ViewModel: TransactionLogViewModelProtocol,
                     Selecting,
                     ObservableObject {
        
        var summaryRefreshTrigger = PublishSubject<Void>()
        
        @Published var summary: CashFlowSummary?
        @Published var sections: [TransactionLogViewModelProtocol.Section]?
        @Published var selectedItems: [Selectable] = []
        
        var dataSource: [Selectable] = []
        var selectedTitle: String = "Test"
        
        var dateType: DateType  = .week()
        
        var pagination: Pagination<TransactionLog>!
        
        let disposeBag = DisposeBag()
        
        init(isEmpty: Bool) {
            pagination = .init(
                observable: { _ in
                    let request = isEmpty ? .just([]) : self.searchTransactionLog()
                    return request
                        .do(onNext: {
                            self.sections = [.init(model: "123456", items: $0)]
                        })
                }
            )
            
            summaryRefreshTrigger
                .flatMapLatest { [unowned self] in
                    self.getCashFlowSummary()
                }
                .subscribe(onNext: {
                    self.summary = $0
                })
                .disposed(by: disposeBag)
        }
        
        func searchTransactionLog() -> Observable<[TransactionLog]> {
            .just((0...10).map {
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
                        externalId: ""
                    ),
                    displayName: .init(title: KNLazyCompanion().create(input: "Test only"))
                )
            })
        }
        
        func getCashFlowSummary() -> Single<CashFlowSummary> {
            .just(
                .init(
                    income: "1234".toAccountCurrency(),
                    outcome: "123".toAccountCurrency()
                )
            )
        }
    }
    
    struct Preview: View {
        @Injected var viewModel: TransactionLogViewModel
        
        let isEmpty: Bool
        
        var body: some View {
            TransactionLogView(
                viewModel: ViewModel(isEmpty: isEmpty),
                playerConfig: PlayerConfigurationImpl()
            )
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
