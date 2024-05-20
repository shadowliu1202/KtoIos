import Combine
import sharedbu
import SwiftUI

extension OfflinePaymentView {
    enum Identifier: String {
        case gatewayForEach
        case gatewayName
        case remitAmountLimitRange
        case remitButton
        case remitBankDropDownText
        case remitterInputText
        case remitBankCardInputText
        case remitAmountInputText
    }
}

struct OfflinePaymentView<ViewModel>: View
    where ViewModel: OfflinePaymentViewModelProtocol & ObservableObject
{
    @Injected private var playerConfiguration: PlayerConfiguration
    @StateObject private var viewModel: ViewModel

    @State private var selectedGatewayId: String? = nil
    @State private var remitBankName: String? = nil
    @State private var remitterName: String? = nil
    @State private var remitBankCardNumber: String? = nil
    @State private var remitAmount: String? = nil

    private let submitRemittanceOnClick: (OfflineDepositDTO.Memo, PaymentsDTO.BankCard) -> Void

    private let publisher: PassthroughSubject<Void, Never> = .init()

    var inspection = Inspection<Self>()

    init(
        viewModel: ViewModel,
        submitRemittanceOnClick: @escaping (OfflineDepositDTO.Memo, PaymentsDTO.BankCard) -> Void)
    {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.submitRemittanceOnClick = submitRemittanceOnClick
    }

    var body: some View {
        SafeAreaReader {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        Text(Localize.string("deposit_offline_step1_title"))
                            .localized(weight: .semibold, size: 24, color: .white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)

                        PickList(selectedGatewayId: $selectedGatewayId)

                        RemittanceInfo(
                            remitBankName: $remitBankName,
                            remitterName: $remitterName,
                            remitBankCardNumber: $remitBankCardNumber,
                            remitAmount: $remitAmount)
                    }
                    .padding(.top, 26)
                    .padding(.bottom, 40)
                }

                PrimaryButton(
                    title: Localize.string("deposit_offline_step1_button"),
                    action: {
                        viewModel.submitRemittance(gatewayId: selectedGatewayId, onClick: submitRemittanceOnClick)
                    })
                    .disabled(viewModel.submitButtonDisable)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .backgroundColor(.greyScaleDefault)
                    .id(OfflinePaymentView.Identifier.remitButton.rawValue)
            }
            .onPageLoading(
                viewModel.gateways.isEmpty || viewModel.remitBankList.isEmpty || viewModel.remitAmountLimitRange
                    .isEmpty)
            .pageBackgroundColor(.greyScaleDefault)
            .environment(\.playerLocale, playerConfiguration.supportLocale)
            .environmentObject(viewModel)
            .onViewDidLoad {
                viewModel.fetchGatewayData()
                viewModel.getRemitterName()
            }
            .onChange(of: viewModel.gateways) { gatewayDMs in
                selectedGatewayId = gatewayDMs.first?.id ?? ""
            }
            .onChange(of: viewModel.remitterName) { remitterName in
                self.remitterName = remitterName
            }
            .onChange(of: selectedGatewayId) { _ in
                publisher.send(())
            }
            .onChange(of: remitBankName) { _ in
                publisher.send(())
            }
            .onChange(of: remitterName) { _ in
                publisher.send(())
            }
            .onChange(of: remitBankCardNumber) { _ in
                publisher.send(())
            }
            .onChange(of: remitAmount) { _ in
                publisher.send(())
            }
            .onReceive(publisher) { _ in
                viewModel.verifyRemitInfo(
                    info: OfflinePaymentDataModel.RemittanceInfo(
                        selectedGatewayId: selectedGatewayId,
                        bankName: remitBankName,
                        remitterName: remitterName,
                        bankCardNumber: remitBankCardNumber,
                        amount: remitAmount))
            }
            .onInspected(inspection, self)
        }
    }
}

extension OfflinePaymentView {
    struct PickList: View {
        @EnvironmentObject var viewModel: ViewModel

        @Binding var selectedGatewayId: String?

        var inspection = Inspection<Self>()

        var body: some View {
            VStack(spacing: 16) {
                Text(Localize.string("deposit_selectbank"))
                    .localized(weight: .medium, size: 16, color: .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)

                VStack(spacing: 0) {
                    Separator()

                    ForEach(viewModel.gateways, id: \.id) { gatewayDM in
                        HStack(spacing: 0) {
                            Image(gatewayDM.iconName)

                            LimitSpacer(16)

                            Text(gatewayDM.name)
                                .localized(weight: .medium, size: 14, color: .white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(OfflinePaymentView.Identifier.gatewayName.rawValue + "-\(gatewayDM.id)")

                            LimitSpacer(8)

                            Image(
                                gatewayDM.id == selectedGatewayId ?
                                    "iconSingleSelectionSelected24" : "iconSingleSelectionEmpty24")
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedGatewayId = gatewayDM.id
                        }

                        Separator()
                            .padding(.leading, 78)
                            .visibility(
                                gatewayDM != viewModel.gateways.last ?
                                    .visible : .gone)
                    }
                    .id(OfflinePaymentView.Identifier.gatewayForEach.rawValue)

                    Separator()
                }
            }
            .onInspected(inspection, self)
        }
    }

    struct RemittanceInfo: View {
        @Environment(\.playerLocale) var playerLocale: SupportLocale

        @EnvironmentObject var viewModel: ViewModel

        @Binding var remitBankName: String?
        @Binding var remitterName: String?
        @Binding var remitBankCardNumber: String?
        @Binding var remitAmount: String?

        var inspection = Inspection<Self>()

        var body: some View {
            VStack(spacing: 16) {
                Text(Localize.string("deposit_my_account_detail"))
                    .localized(weight: .semibold, size: 16, color: .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    SwiftUIDropDownText(
                        placeHolder: Localize.string("deposit_bankname_placeholder"),
                        textFieldText: $remitBankName ?? "",
                        errorText: viewModel.remitInfoErrorMessage.bankName,
                        items: viewModel.remitBankList,
                        featureType: .inputAssisted,
                        dropDownArrowVisible: false)
                        .id(OfflinePaymentView.Identifier.remitBankDropDownText.rawValue)

                    SwiftUIInputText(
                        placeHolder: Localize.string("deposit_name"),
                        textFieldText: $remitterName ?? "",
                        errorText: viewModel.remitInfoErrorMessage.remitterName,
                        textFieldType: GeneralType(regex: .all))
                        .id(OfflinePaymentView.Identifier.remitterInputText.rawValue)

                    SwiftUIInputText(
                        placeHolder: Localize.string("deposit_accountlastfournumber"),
                        textFieldText: $remitBankCardNumber ?? "",
                        errorText: viewModel.remitInfoErrorMessage.bankCardNumber,
                        textFieldType: GeneralType(
                            regex: .number,
                            keyboardType: .numberPad,
                            disablePaste: false,
                            maxLength: 4))
                        .id(OfflinePaymentView.Identifier.remitBankCardInputText.rawValue)

                    SwiftUIInputText(
                        placeHolder: Localize.string("deposit_amount"),
                        textFieldText: $remitAmount ?? "",
                        errorText: viewModel.remitInfoErrorMessage.amount,
                        textFieldType: CurrencyType(regex: .noDecimal))
                        .id(OfflinePaymentView.Identifier.remitAmountInputText.rawValue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.remitAmountLimitRange)
                            .id(OfflinePaymentView.Identifier.remitAmountLimitRange.rawValue)

                        Text(Localize.string("common_notify_currency_ratio"))
                            .visibility(playerLocale == SupportLocale.Vietnam() ? .visible : .gone)
                    }
                    .localized(weight: .medium, size: 14, color: .textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 30)
            .onInspected(inspection, self)
        }
    }
}

struct OfflinePaymentView_Previews: PreviewProvider {
    class FakePresenter: OfflinePaymentViewModelProtocol, ObservableObject {
        var remitInfoErrorMessage: OfflinePaymentDataModel.RemittanceInfoError = .init(
            bankName: "",
            remitterName: "",
            bankCardNumber: "",
            amount: "")

        @Published var gateways: [OfflinePaymentDataModel.Gateway]
            = [
                OfflinePaymentDataModel.Gateway(id: "1", name: "中国银行", iconName: "CNY-12"),
                OfflinePaymentDataModel.Gateway(id: "2", name: "中国工商银行", iconName: "CNY-1"),
                OfflinePaymentDataModel.Gateway(id: "3", name: "中国农民银行", iconName: "CNY-3")
            ]

        @Published var remitBankList: [String] = ["中国银行", "中国工商银行", "中国农民银行", "中国建设银行", "交通银行", "中國信託", "玉山銀行"]

        @Published var remitAmountLimitRange = "充值单笔限额：50.00-100,000.00"

        var remittanceErrorMessage = ""

        var remitterName = "testRemitter"

        @Published var submitButtonDisable = true

        func fetchGatewayData() { }

        func getRemitterName() { }

        func verifyRemitInfo(info _: OfflinePaymentDataModel.RemittanceInfo) { }

        func submitRemittance(
            gatewayId _: String?,
            onClick _: @escaping (OfflineDepositDTO.Memo, PaymentsDTO.BankCard) -> Void) { }
    }

    static var previews: some View {
        OfflinePaymentView(viewModel: FakePresenter(), submitRemittanceOnClick: { _, _ in })
    }
}
