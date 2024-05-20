import sharedbu
import SwiftUI

struct WithdrawalCryptoWalletDetailView<ViewModel>: View
    where ViewModel: WithdrawalCryptoWalletDetailViewModelProtocol & ObservableObject
{
    @StateObject var viewModel: ViewModel

    let wallet: WithdrawalDto.CryptoWallet

    var onDelete: (() -> Void)?
    var onDeleteSuccess: (() -> Void)?

    var inspection = Inspection<Self>()

    var body: some View {
        WalletDetail(
            models: [
                .init(
                    title: Localize.string("cps_crypto_account_name"),
                    content: viewModel.wallet?.name),
                .init(
                    title: Localize.string("cps_crypto_currency"),
                    content: viewModel.wallet?.type.name),
                .init(
                    title: Localize.string("cps_crypto_network"),
                    content: viewModel.wallet?.network.name),
                .init(
                    title: Localize.string("cps_wallet_address"),
                    content: viewModel.wallet?.address),
            ],
            status: viewModel.wallet?.verifyStatus.statusConfig(isCrypto: true).text ?? "",
            deletable: viewModel.wallet?.isDeletable ?? false,
            deleteActionDisable: viewModel.isDeleteButtonDisable,
            onDelete: onDelete)
            .environmentObject(viewModel)
            .environment(\.playerLocale, viewModel.supportLocale)
            .onChange(of: viewModel.isDeleteSuccess) {
                guard $0 else { return }
                onDeleteSuccess?()
            }
            .onInspected(inspection, self)
            .onViewDidLoad {
                viewModel.prepareForAppear(wallet: wallet)
            }
    }
}

struct WithdrawalCryptoWalletDetailView_Previews: PreviewProvider {
    class ViewModel: WithdrawalCryptoWalletDetailViewModelProtocol, ObservableObject {
        var supportLocale: SupportLocale = .China()
        var isDeleteSuccess = false
        var isDeleteButtonDisable = false
        var wallet: WithdrawalDto.CryptoWallet? = .init(
            name: "test",
            walletId: "test id",
            isDeletable: true,
            verifyStatus: .pending,
            type: .eth,
            network: .erc20,
            address: "dsfjsjdflkjsdlfjksldfjlskdjflsk\ndlsdjflksdjflkjs",
            limitation: .init(
                maxCount: 0, maxAmount: .zero(),
                currentCount: 0, currentAmount: .zero(),
                oneOffMinimumAmount: .zero(), oneOffMaximumAmount: .zero()),
            remainTurnOver: .zero())

        func prepareForAppear(wallet _: WithdrawalDto.CryptoWallet) { }
        func deleteWallet() { }
    }

    static var previews: some View {
        WithdrawalCryptoWalletDetailView(viewModel: ViewModel(), wallet: ViewModel().wallet!)
    }
}
