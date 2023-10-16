import sharedbu
import SwiftUI

struct WithdrawalFiatWalletDetailView<ViewModel>: View
  where ViewModel: WithdrawalFiatWalletDetailViewModelProtocol & ObservableObject
{
  @StateObject var viewModel: ViewModel

  let wallet: WithdrawalDto.FiatWallet

  var onDelete: (() -> Void)?
  var onDeleteSuccess: (() -> Void)?

  var inspection = Inspection<Self>()

  var body: some View {
    WalletDetail(
      models: [
        .init(
          title: Localize.string("withdrawal_accountrealname"),
          content: viewModel.realName),
        .init(
          title: Localize.string("common_bank"),
          content: viewModel.wallet?.name),
        .init(
          title: Localize.string("withdrawal_branch"),
          content: viewModel.wallet?.bankAccount.branch),
        .init(
          title: Localize.string("withdrawal_bankstate"),
          content: viewModel.wallet?.bankAccount.location),
        .init(
          title: Localize.string("withdrawal_bankcity"),
          content: viewModel.wallet?.bankAccount.city),
        .init(
          title: Localize.string("withdrawal_accountnumber"),
          content: viewModel.wallet?.accountNumber),
      ],
      status: viewModel.wallet?.verifyStatus.statusConfig(isCrypto: false).text ?? "",
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
        viewModel.loadRealName()
      }
  }
}

struct WithdrawalFiatWalletDetailView_Previews: PreviewProvider {
  class ViewModel: WithdrawalFiatWalletDetailViewModelProtocol, ObservableObject {
    var supportLocale: SupportLocale = .China()
    var realName = "Tester"
    var isDeleteSuccess = false
    var isDeleteButtonDisable = false
    var wallet: WithdrawalDto.FiatWallet? = .init(
      walletId: "test id",
      name: "test bank",
      isDeletable: true,
      verifyStatus: .verified,
      bankAccount: .init(
        bankId: 0,
        branch: "test branch",
        accountName: "test accountName",
        accountNumber: "test accountNumber",
        city: "test city",
        location: "test location"),
      limitation: .init(
        maxCount: 0, maxAmount: .zero(),
        currentCount: 0, currentAmount: .zero(),
        oneOffMinimumAmount: .zero(), oneOffMaximumAmount: .zero()))

    func prepareForAppear(wallet _: WithdrawalDto.FiatWallet) { }
    func loadRealName() { }
    func deleteWallet() { }
  }

  static var previews: some View {
    WithdrawalFiatWalletDetailView(viewModel: ViewModel(), wallet: ViewModel().wallet!)
  }
}
