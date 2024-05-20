import SwiftUI

@available(*, deprecated, message: "Waiting for refactor.")
struct WalletSelector: View {
    @Binding var isEditing: Bool

    let wallets: [WalletRowModel]
    let isCrypto: Bool

    var onEditTapped: (() -> Void)?
    var onWalletSelected: ((_ model: WalletRowModel, _ isEditing: Bool) -> Void)?

    init(
        isEditing: Binding<Bool>,
        wallets: [WalletRowModel],
        isCrypto: Bool,
        onEditTapped: (() -> Void)? = nil,
        onWalletSelected: ((_: WalletRowModel, _: Bool) -> Void)? = nil)
    {
        self._isEditing = isEditing
        self.wallets = wallets
        self.isCrypto = isCrypto
        self.onEditTapped = onEditTapped
        self.onWalletSelected = onWalletSelected
    }

    var body: some View {
        VStack(spacing: 30) {
            Text(key: isEditing ? "withdrawal_setaccount" : "withdrawal_selectbankcard")
                .localized(
                    weight: .semibold,
                    size: 24,
                    color: .greyScaleWhite)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)

            VStack(spacing: 0) {
                Separator()

                ForEach(wallets, id: \.accountNumber) { wallet in
                    Row(
                        model: wallet,
                        isEditing: isEditing,
                        isCrypto: isCrypto,
                        onSelected: onWalletSelected)
                }

                Button(
                    action: {
                        onEditTapped?()
                    },
                    label: {
                        HStack(spacing: 16) {
                            Image(isEditing ? "Add" : "Default(32)")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)

                            Text(key: isEditing ? "withdrawal_setbankaccount_button" : "withdrawal_setaccount")
                                .localized(
                                    weight: .medium,
                                    size: 14,
                                    color: .greyScaleWhite)
                        }
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    })
                    .padding(.leading, 30)

                Separator()
            }
            .backgroundColor(.greyScaleList)
        }
    }
}
