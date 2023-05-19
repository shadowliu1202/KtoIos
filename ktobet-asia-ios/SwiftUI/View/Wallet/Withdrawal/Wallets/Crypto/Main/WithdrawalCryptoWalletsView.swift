import SharedBu
import SwiftUI

struct WithdrawalCryptoWalletsView<ViewModel>: View
  where ViewModel: ObservableObject & WithdrawalCryptoWalletsViewModelProtocol
{
  @StateObject var viewModel: ViewModel

  var toAddWallet: (() -> Void)?
  var toBack: (() -> Void)?
  var onUpToMaximum: (() -> Void)?
  var onWalletSelected: ((_ model: WithdrawalDto.CryptoWallet, _ isEditing: Bool) -> Void)?

  var inspection = Inspection<Self>()

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        if let wallets = viewModel.playerWallet?.wallets {
          if wallets.isEmpty {
            WalletEmptyView(
              titleTextKey: "cps_set_crypto_account",
              descriptionTextKey: "cps_set_crypto_account_hint",
              toAddWallet: toAddWallet,
              toBack: toBack)
          }
          else {
            WalletSelector(
              isEditing: $viewModel.isEditing,
              wallets: wallets,
              isCrypto: true,
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
                guard let wallet = $0 as? WithdrawalDto.CryptoWallet else { return }
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

struct WithdrawalCryptoWalletsView_Previews: PreviewProvider {
  class ViewModel: WithdrawalCryptoWalletsViewModelProtocol, ObservableObject {
    var isEditing = false
    var supportLocale: SupportLocale = .China()
    var playerWallet: WithdrawalDto.PlayerCryptoWallet?
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
              name: "test \($0)",
              walletId: "test Id \($0)",
              isDeletable: false,
              verifyStatus: .pending,
              type: .eth,
              network: .erc20,
              address: "\($0)fdsfasfdfashdfgajlsdhfljjhdsjkaldsljflksdjflksdjflksjdlfkjslkdjfklsjdfklsj",
              limitation: .init(
                maxCount: 0, maxAmount: .zero(),
                currentCount: 0, currentAmount: .zero(),
                oneOffMinimumAmount: .zero(), oneOffMaximumAmount: .zero()),
              remainTurnOver: .zero())
            },
          maxAmount: 3)
      }
    }
  }

  static var previews: some View {
    WithdrawalCryptoWalletsView(viewModel: ViewModel(isEmpty: true))
    WithdrawalCryptoWalletsView(viewModel: ViewModel(isEmpty: false))
  }
}
