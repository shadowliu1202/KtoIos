import sharedbu
import SwiftUI

protocol WalletRowModel {
    var title: String { get }
    var accountNumber: String { get }
    var verifyStatus: Wallet.VerifyStatus { get }
}

extension Wallet.VerifyStatus {
    func statusConfig(isCrypto: Bool) -> (text: String, color: UIColor) {
        switch self {
        case .pending:
            return (Localize.string("withdrawal_bankcard_new"), .textPrimary)
        case .void:
            return (Localize.string("withdrawal_bankcard_fail"), .primaryDefault)
        case .onHold:
            return (Localize.string("withdrawal_bankcard_locked"), .alert)
        case .verified:
            return (Localize.string(isCrypto ? "cps_account_status_verified" : "withdrawal_bankcard_verified"), .statusSuccess)
        case .unknown:
            return ("", .clear)
        }
    }
}

extension WalletSelector {
    @available(*, deprecated, message: "Waiting for refactor.")
    struct Row: View {
        let model: WalletRowModel
        let isEditing: Bool
        let isCrypto: Bool

        var onSelected: ((_ model: WalletRowModel, _ isEditing: Bool) -> Void)?

        var body: some View {
            VStack(spacing: 16) {
                LimitSpacer(0)

                HStack(spacing: 8) {
                    VStack(spacing: 9) {
                        Text(model.title)
                            .localized(
                                weight: .medium,
                                size: 14,
                                color: .greyScaleWhite)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(model.accountNumber)
                            .localized(
                                weight: .medium,
                                size: 14,
                                color: .textPrimary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(model.verifyStatus.statusConfig(isCrypto: isCrypto).text)
                            .localized(
                                weight: .regular,
                                size: 14,
                                color: model.verifyStatus.statusConfig(isCrypto: isCrypto).color)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Image("iconChevronRight16")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 16, height: 16)
                        .visibility(isEditing ? .gone : .visible)
                }
                .padding(.leading, 30)
                .padding(.trailing, 16)

                Separator()
                    .padding(.leading, 30)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelected?(model, isEditing)
            }
        }
    }
}

struct WalletRow_Previews: PreviewProvider {
    struct Model: WalletRowModel {
        var title = "test 1"
        var accountNumber = "e94803oireioep2900439039420849r540xpre34422reioep290043903942ep290043903942"
        var verifyStatus: Wallet.VerifyStatus = .verified
    }

    static var previews: some View {
        VStack {
            WalletSelector.Row(model: Model(), isEditing: true, isCrypto: false)
                .backgroundColor(.greyScaleList)
            WalletSelector.Row(model: Model(), isEditing: false, isCrypto: true)
                .backgroundColor(.greyScaleList)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundColor(.black)
    }
}
