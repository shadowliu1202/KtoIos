import SwiftUI

struct WalletEmptyView: View {
  let titleTextKey: String
  let descriptionTextKey: String

  var toAddWallet: (() -> Void)?
  var toBack: (() -> Void)?

  var body: some View {
    VStack(spacing: 40) {
      VStack(spacing: 12) {
        Text(key: titleTextKey)
          .localized(
            weight: .semibold,
            size: 24,
            color: .greyScaleWhite)
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(key: descriptionTextKey)
          .localized(
            weight: .medium,
            size: 14,
            color: .textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      VStack(spacing: 24) {
        PrimaryButton(
          title: Localize.string("common_continue"),
          action: {
            toAddWallet?()
          })
        
        Button(
          action: {
            toBack?()
          },
          label: {
            Text(key: "common_notset")
              .localized(
                weight: .regular,
                size: 14,
                color: .primaryDefault)
          })
      }
    }
    .padding(.horizontal, 30)
  }
}

struct WalletEmptyView_Previews: PreviewProvider {
  static var previews: some View {
    WalletEmptyView(
      titleTextKey: "cps_set_crypto_account",
      descriptionTextKey: "cps_set_crypto_account_hint")
    WalletEmptyView(
      titleTextKey: "withdrawal_setbankaccount_title",
      descriptionTextKey: "withdrawal_setbankaccount_tips")
  }
}
