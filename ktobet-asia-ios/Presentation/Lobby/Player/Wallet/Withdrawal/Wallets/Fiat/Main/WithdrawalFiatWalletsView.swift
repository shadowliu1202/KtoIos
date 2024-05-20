import sharedbu
import SwiftUI

struct WithdrawalFiatWalletsView<ViewModel>: View
    where ViewModel: ObservableObject & WithdrawalFiatWalletsViewModelProtocol
{
    @StateObject var viewModel: ViewModel

    var toAddWallet: (() -> Void)?
    var toBack: (() -> Void)?
    var onUpToMaximum: (() -> Void)?
    var onWalletSelected: ((_ model: WithdrawalDto.FiatWallet, _ isEditing: Bool) -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
        ScrollView(showsIndicators: false) {
            PageContainer {
                if let wallets = viewModel.playerWallet?.wallets {
                    if wallets.isEmpty {
                        WalletEmptyView(
                            titleTextKey: "withdrawal_setbankaccount_title",
                            descriptionTextKey: "withdrawal_setbankaccount_tips",
                            toAddWallet: toAddWallet,
                            toBack: toBack)
                    }
                    else {
                        WalletSelector(
                            isEditing: $viewModel.isEditing,
                            wallets: wallets,
                            isCrypto: false,
                            onEditTapped: {
                                if viewModel.isEditing {
                                    if viewModel.isUpToMaximum {
                                        onUpToMaximum?()
                                    }
                                    else {
                                        toAddWallet?()
                                    }
                                }
                                else {
                                    viewModel.isEditing = !viewModel.isEditing
                                }
                            },
                            onWalletSelected: {
                                guard let wallet = $0 as? WithdrawalDto.FiatWallet else { return }
                                onWalletSelected?(wallet, $1)
                            })
                    }
                }
                else {
                    EmptyView()
                }
            }
        }
        .environment(\.playerLocale, viewModel.supportLocale)
        .onPageLoading(viewModel.playerWallet == nil)
        .pageBackgroundColor(.greyScaleDefault)
        .onAppear {
            viewModel.observeWallets()
        }
        .onDisappear {
            viewModel.resetDisposeBag()
        }
        .onInspected(inspection, self)
    }
}

struct WithdrawalFiatWalletsView_Previews: PreviewProvider {
    class ViewModel: WithdrawalFiatWalletsViewModelProtocol, ObservableObject {
        var isEditing = false
        var supportLocale: SupportLocale = .China()
        var playerWallet: WithdrawalDto.PlayerFiatWallet?
        var isUpToMaximum = false

        func observeWallets() { }

        func resetDisposeBag() { }

        init(isEmpty: Bool) {
            if isEmpty {
                playerWallet = .init(wallets: [], maxAmount: 0)
            }
            else {
                playerWallet = .init(
                    wallets: (0..<3)
                        .map { .init(
                            walletId: "test id \($0)",
                            name: "test name \($0)",
                            isDeletable: true,
                            verifyStatus: .pending,
                            bankAccount: .init(
                                bankId: $0,
                                branch: "",
                                accountName: "",
                                accountNumber: "",
                                city: "",
                                location: ""),
                            limitation: .init(
                                maxCount: 0,
                                maxAmount: .zero(),
                                currentCount: 0,
                                currentAmount: .zero(),
                                oneOffMinimumAmount: .zero(),
                                oneOffMaximumAmount: .zero()))
                        },
                    maxAmount: 3)
            }
        }
    }

    static var previews: some View {
        WithdrawalFiatWalletsView(viewModel: ViewModel(isEmpty: true))
        WithdrawalFiatWalletsView(viewModel: ViewModel(isEmpty: false))
    }
}
