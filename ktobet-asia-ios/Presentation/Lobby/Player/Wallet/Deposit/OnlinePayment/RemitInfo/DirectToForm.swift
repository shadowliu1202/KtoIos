import SwiftUI

extension OnlinePaymentView.Identifier {
    enum RemittanceInfo_DirectTo: String {
        case amountRangeHint
        case amountOptionHint
        case textFieldInputAmount
        case textFieldOptionAmount
        case textFieldBankList
    }
}

extension OnlinePaymentView.RemittanceInfo {
    @ViewBuilder
    func directToForm(_ gateway: OnlinePaymentDataModel.Gateway) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localize.string("deposit_selectpaymentgateway"))
                    .localized(weight: .medium, size: 16, color: .textPrimary)

                SwiftUIDropDownText(
                    placeHolder: Localize.string("deposit_select_bank"),
                    textFieldText: $supportBankName ?? "",
                    items: gateway.remitBanks,
                    featureType: .select,
                    onInputTextTap: {
                        focusSelection = .focusOnBank
                    })
                    .id(OnlinePaymentView.Identifier.RemittanceInfo_DirectTo.textFieldBankList.rawValue)
            }
            .zIndex(focusSelection == .focusOnBank ? 1 : 0)

            VStack(alignment: .leading, spacing: 16) {
                Text(Localize.string("deposit_my_account_detail"))
                    .localized(weight: .medium, size: 16, color: .textPrimary)

                VStack(spacing: 12) {
                    SwiftUIInputText(
                        placeHolder: Localize.string("deposit_name"),
                        textFieldText: $remitterName ?? "",
                        errorText: viewModel.remitInfoErrorMessage.remitterName,
                        textFieldType: GeneralType())

                    SwiftUIInputText(
                        placeHolder: Localize.string("deposit_accountlastfournumber"),
                        textFieldText: $remitterAccountNumber ?? "",
                        errorText: viewModel.remitInfoErrorMessage.remitterAccountNumber,
                        textFieldType: GeneralType(
                            regex: .number,
                            keyboardType: .numberPad,
                            maxLength: 4))
                        .visibility(gateway.isAccountNumberDenied ? .gone : .visible)

                    switch gateway.cashType {
                    case .input(let limitation, let isFloatAllowed):
                        SwiftUIInputText(
                            placeHolder: Localize.string("deposit_amount"),
                            textFieldText: $remitAmount ?? "",
                            errorText: viewModel.remitInfoErrorMessage.remitAmount,
                            textFieldType: CurrencyType(
                                regex: isFloatAllowed ? .withDecimal(4) : .noDecimal))
                            .id(OnlinePaymentView.Identifier.RemittanceInfo_DirectTo.textFieldInputAmount.rawValue)

                        Text(Localize.string(
                            "deposit_offline_step1_tips",
                            limitation.min,
                            limitation.max))
                            .localized(weight: .medium, size: 14, color: .textPrimary)
                            .id(OnlinePaymentView.Identifier.RemittanceInfo_DirectTo.amountRangeHint.rawValue)

                    case .option(let amountList):
                        SwiftUIDropDownText(
                            placeHolder: Localize.string("deposit_amount"),
                            textFieldText: $remitAmount ?? "",
                            errorText: viewModel.remitInfoErrorMessage.remitAmount,
                            items: amountList,
                            featureType: .select,
                            onInputTextTap: {
                                focusSelection = .focusOnOptionAmount
                            })
                            .id(OnlinePaymentView.Identifier.RemittanceInfo_DirectTo.textFieldOptionAmount.rawValue)

                        Text(Localize.string("deposit_amount_option_hint"))
                            .localized(weight: .medium, size: 14, color: .textPrimary)
                            .id(OnlinePaymentView.Identifier.RemittanceInfo_DirectTo.amountOptionHint.rawValue)
                    }
                }
            }
            .zIndex(focusSelection == .focusOnOptionAmount ? 1 : 0)
        }
    }
}
