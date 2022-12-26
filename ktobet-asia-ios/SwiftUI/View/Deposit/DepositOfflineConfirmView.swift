import SwiftUI
import SharedBu
import RxCocoa

struct DepositOfflineConfirmView<ViewModel>: View
    where ViewModel: DepositOfflineConfirmViewModelProtocol & ObservableObject
{
    @StateObject var viewModel: ViewModel
    
    let memo: OfflineDepositDTO.Memo
    let selectedBank: PaymentsDTO.BankCard
    
    var onCopyed: (() -> Void)?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            PageContainer {
                VStack(spacing: 0) {
                    Header()
                    
                    LimitSpacer(30)
                    
                    Section(
                        title: Localize.string("deposit_payee_detail"),
                        rowTypes: [
                            .receiveBank,
                            .branch,
                            .receiveName,
                            .receiveBankAccount,
                            .validTime
                        ],
                        onCopyed: onCopyed
                    )
                    
                    if viewModel.locale == .China() {
                        LimitSpacer(30)
                        
                        Section(
                            title: Localize.string("deposit_offline_remitter_title"),
                            rowTypes: [
                                .remitterName,
                                .customRemitAmount
                            ]
                        )
                        
                        LimitSpacer(12)
                        
                        Text(Localize.string("deposit_offline_summary_tip"))
                            .localized(
                                weight: .medium,
                                size: 14,
                                color: .gray9B9B9B
                            )
                    }
                    
                    LimitSpacer(40)
                    
                    Button(
                        action: {
                            viewModel.depositTrigger.onNext(())
                        },
                        label: {
                            Text(Localize.string("common_submit2"))
                                .localized(
                                    weight: .regular,
                                    size: 16,
                                    color: .whitePure
                                )
                        }
                    )
                    .buttonStyle(.confirmRed)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 30)
        }
        .pageBackgroundColor(.gray131313)
        .environment(\.playerLocale, viewModel.locale)
        .environmentObject(viewModel)
        .onAppear {
            viewModel.prepareForAppear(
                memo: memo,
                selectedBank: selectedBank
            )
            viewModel.startCounting()
        }
    }
}

extension DepositOfflineConfirmView {
    
    struct Header: View {
        
        var body: some View {
            VStack(spacing: 12) {
                Group {
                    Text(Localize.string("deposit_offline_step2_title"))
                        .localized(
                            weight: .semibold,
                            size: 24,
                            color: .whitePure
                        )
                    
                    Text(Localize.string("deposit_offline_step2_title_tips"))
                        .localized(
                            weight: .medium,
                            size: 14,
                            color: .gray9B9B9B
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    struct Section: View {
        @EnvironmentObject var viewModel: ViewModel
        @Environment(\.playerLocale) var locale: SupportLocale
        
        let title: String
        let rowTypes: [DepositOfflineConfirmView.Row.`Type`]
        
        var onCopyed: (() -> Void)?
        
        var body: some View {
            VStack(spacing: 16) {
                Text(title)
                    .localized(
                        weight: .medium,
                        size: 16,
                        color: .gray9B9B9B
                    )
                
                VStack(spacing: 12) {
                    ForEach(rowTypes, id: \.self) {
                        DepositOfflineConfirmView.Row(
                            type: $0,
                            onCopyed: onCopyed
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
                .strokeBorder(color: .gray9B9B9B, cornerRadius: 14)
            }
        }
    }
    
    struct Row: View {
        enum `Type` {
            case receiveBank
            case branch
            case receiveName
            case receiveBankAccount
            case validTime
            case remitterName
            case customRemitAmount
        }
        
        @EnvironmentObject var viewModel: ViewModel
        @Environment(\.playerLocale) var locale: SupportLocale
        
        let type: `Type`
        
        var onCopyed: (() -> Void)?
        
        var inspection = Inspection<Self>()
        
        var body: some View {
            switch type {
            case .receiveBank:
                buildView(
                    stringTag: "deposit_receivebank",
                    content: viewModel.receiverInfo.bank,
                    imageName: viewModel.receiverInfo.bankImage,
                    onCopyed: onCopyed
                )
            case .branch:
                buildView(
                    stringTag: "deposit_branch",
                    content: viewModel.receiverInfo.branch,
                    onCopyed: onCopyed
                )
            case .receiveName:
                buildView(
                    stringTag: "deposit_receivename",
                    content: viewModel.receiverInfo.receiver,
                    onCopyed: onCopyed
                )
            case .receiveBankAccount:
                buildView(
                    stringTag: "deposit_receiveaccount",
                    content: viewModel.receiverInfo.bankAccount,
                    onCopyed: onCopyed
                )
            case .validTime:
                buildCounting()
                
            case .remitterName:
                buildView(
                    stringTag: "deposit_name",
                    content: viewModel.remitTip.name,
                    isCopy: false
                )
                
            case .customRemitAmount:
                buildCustomAmount()
            }
        }
        
        private func buildView(
            stringTag: String,
            content: String?,
            imageName: String? = nil,
            isCopy: Bool = true,
            onCopyed: (() -> Void)? = nil
        ) -> some View {
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localize.string(stringTag))
                        .localized(
                            weight: .regular,
                            size: 14,
                            color: .gray9B9B9B
                        )
                    
                    HStack(spacing: 6) {
                        Text(content ?? "")
                            .localized(
                                weight: .regular,
                                size: 16,
                                color: .whitePure
                            )
                        
                        if let imageName = imageName {
                            Image(imageName)
                                .resizable()
                                .frame(
                                    width: locale is SupportLocale.China ? 16 : 48,
                                    height: 16
                                )
                        }
                    }
                }
                
                Spacer()
                
                Button(
                    action: {
                        UIPasteboard.general.string = content
                        onCopyed?()
                    },
                    label: {
                        Text(Localize.string("common_copy"))
                            .localized(
                                weight: .medium,
                                size: 12,
                                color: .gray9B9B9B
                            )
                            .padding(4)
                    }
                )
                .strokeBorder(color: .gray9B9B9B, cornerRadius: 4)
                .visibility(isCopy ? .visible : .gone)
            }
            .onInspected(inspection, self)
        }
        
        private func buildCounting() -> some View {
            HStack {
                Text(Localize.string("deposit_validdeposittime"))
                    .localized(
                        weight: .regular,
                        size: 14,
                        color: .gray9B9B9B
                    )
                
                Spacer()
                
                Text(viewModel.validTimeString)
                    .localized(
                        weight: .medium,
                        size: 14,
                        color: .yellowFFD500
                    )
            }
            .onInspected(inspection, self)
        }
        
        private func buildCustomAmount() -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localize.string("deposit_custom_cash"))
                    .localized(
                        weight: .regular,
                        size: 14,
                        color: .gray9B9B9B
                    )
                
                UIKitLabel {
                    $0.attributedText = viewModel.remitTip.amountAttributedString
                }
            }
            .onInspected(inspection, self)
        }
    }
}

struct DepositOfflineConfirmView_Previews: PreviewProvider {

    class ViewModel: ObservableObject, DepositOfflineConfirmViewModelProtocol {
        var receiverInfo: DepositOfflineConfirmModel.ReceiverInfo = .init(
            identity: "",
            bank: "Test bank",
            bankImage: "CNY-1",
            branch: "Test branch",
            receiver: "Me",
            bankAccount: "1234-5678-9011",
            validTimeLeftHour: 0
        )
        
        var remitTip: DepositOfflineConfirmModel.RemitTip = .init(
            name: "You",
            amountAttributedString: "9527.12".attributed
                .textColor(.whitePure)
                .font(weight: .semibold, locale: .China(), size: 24)
                .highlights(
                    weight: .semibold,
                    locale: .China(),
                    size: 24,
                    color: .orangeFF8000,
                    subStrings: ["12"]
                )
        )
        
        func prepareForAppear(memo: OfflineDepositDTO.Memo, selectedBank: PaymentsDTO.BankCard) { }

        var validTimeString: String = "02 : 49 : 59"
        var locale: SupportLocale = .China()
        
        var depositTrigger: PublishSubject<Void> = .init()
        var expiredDriver: Driver<Void> { Observable.just(()).asDriverLogError() }
        var depositSuccessDriver: Driver<Void> { Observable.just(()).asDriverLogError() }

        func startCounting() { }
    }

    static var previews: some View {
        DepositOfflineConfirmView(
            viewModel: ViewModel(),
            memo: .init(identity: "", remitter: .init(name: "", account: "", bankName: ""), remittance: "".toAccountCurrency(), beneficiary: .init(name: "", branch: "", account: .init(accountName: "", accountNumber: "")), expiredHour: 0),
            selectedBank: .init(identity: "", bankId: "", name: "", verifier: .init())
        )
    }
}
