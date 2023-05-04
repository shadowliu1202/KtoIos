import SwiftUI

struct WalletEmptyView: View {
  let isCrypto: Bool

  var toAddWallet: (() -> Void)?
  var toBack: (() -> Void)?

  var body: some View {
    VStack(spacing: 40) {
      VStack(spacing: 12) {
        Text(key: isCrypto ? "cps_set_crypto_account" : "withdrawal_setbankaccount_title")
          .localized(
            weight: .semibold,
            size: 24,
            color: .whitePure)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(key: isCrypto ? "cps_set_crypto_account_hint" : "withdrawal_setbankaccount_tips")
          .localized(
            weight: .medium,
            size: 14,
            color: .gray9B9B9B)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      VStack(spacing: 24) {
        Button(
          action: {
            toAddWallet?()
          },
          label: {
            Text(key: "common_continue")
          })
          .buttonStyle(ConfirmRed(size: 16))

        Button(
          action: {
            toBack?()
          },
          label: {
            Text(key: "common_notset")
              .localized(
                weight: .regular,
                size: 14,
                color: .redF20000)
          })
      }
    }
    .padding(.horizontal, 30)
  }
}
