import SwiftUI

extension OnlinePaymentView.Identifier {
    enum RemittanceInfo_OnlyAmount: String {
        case amountRangeHint
        case amountOptionHint
        case textFieldInputAmount
        case textFieldOptionAmount
    }
}

extension OnlinePaymentView.RemittanceInfo {
    @ViewBuilder
    func onlyAmountForm(_ gateway: OnlinePaymentDataModel.Gateway) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localize.string("deposit_my_account_detail"))
                .localized(weight: .medium, size: 16, color: .textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                switch gateway.cashType {
                case .input(let limitation, let isFloatAllowed):
                    SwiftUIInputText(
                        placeHolder: Localize.string("deposit_amount"),
                        textFieldText: $remitAmount ?? "",
                        errorText: viewModel.remitInfoErrorMessage.remitAmount,
                        textFieldType: CurrencyType(
                            regex: isFloatAllowed ? .withDecimal(4) : .noDecimal))
                        .id(OnlinePaymentView.Identifier.RemittanceInfo_OnlyAmount.textFieldInputAmount.rawValue)

                    Text(Localize.string(
                        "deposit_offline_step1_tips",
                        limitation.min,
                        limitation.max))
                        .localized(weight: .medium, size: 14, color: .textPrimary)
                        .id(OnlinePaymentView.Identifier.RemittanceInfo_OnlyAmount.amountRangeHint.rawValue)

                case .option(let amountList):
                    SwiftUIDropDownText(
                        placeHolder: Localize.string("deposit_amount"),
                        textFieldText: $remitAmount ?? "",
                        errorText: viewModel.remitInfoErrorMessage.remitAmount,
                        items: amountList,
                        featureType: .select)
                        .id(OnlinePaymentView.Identifier.RemittanceInfo_OnlyAmount.textFieldOptionAmount.rawValue)

                    Text(Localize.string("deposit_amount_option_hint"))
                        .localized(weight: .medium, size: 14, color: .textPrimary)
                        .id(OnlinePaymentView.Identifier.RemittanceInfo_OnlyAmount.amountOptionHint.rawValue)
                }
            }
        }
    }
}
