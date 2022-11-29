import SwiftUI
import SharedBu
import RxSwift
import Combine

struct OnlinePaymentView<ViewModel: OnlineDepositViewModelProtocol & CollectErrorViewModelProtocol & ObservableObject>: View {
    enum Identifier: String {
        case RemitButton
        case RemittanceInputTextField
    }
    
    var inspection = Inspection<Self>()
    
    @StateObject var viewModel: ViewModel
    
    @State var selectedGateway: PaymentsDTO.Gateway? = nil
    @State var amount: String = ""
    
    @State private var remitterName: String = ""
    @State private var submitInProgress = false
    
    var userGuideOnTap = {}
    var remitButtonOnSuccess = { (webPath: CommonDTO.WebPath) in }
    
    private let disposeBag = DisposeBag()
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    Text(viewModel.selectedOnlinePayment.name)
                        .localized(weight: .semibold, size: 24, color: .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                    
                    if let selectedGateway = selectedGateway, selectedGateway.isInstructionDisplayed {
                        userGuide
                    }
                    
                    LimitSpacer(30)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localize.string("deposit_select_method"))
                            .localized(weight: .medium, size: 16, color: .gray9B9B9B)
                            .padding(.horizontal, 30)
                        
                        PickList(selectedItem: $selectedGateway, items: viewModel.gateways)
                    }
                    
                    LimitSpacer(30)
                    
                    remitInfo
                    
                    LimitSpacer(40)
                    
                    Button {
                        viewModel.submitRemittance(gatewayIdentity: selectedGateway!.identity, remitterName: remitterName, remittance: amount)
                            .do(onSubscribe: {
                                submitInProgress = true
                            }, onDispose: {
                                submitInProgress = false
                            })
                            .compose(viewModel.applySingleErrorHandler())
                            .subscribe(onSuccess: { webPath in
                                remitButtonOnSuccess(webPath)
                            })
                            .disposed(by: disposeBag)
                    } label: {
                        Text(Localize.string("deposit_offline_step1_button"))
                    }
                    .buttonStyle(.confirmRed)
                    .padding(.horizontal, 30)
                    .disabled(!isOnlineDataValid() || submitInProgress)
                    .id(Identifier.RemitButton.rawValue)
                }
            }
        }
        .pageBackgroundColor(.gray131313)
        .onAppear {
            if remitterName.isEmpty {
                viewModel.getRemitterName()
                    .subscribe(onSuccess: { name in
                        self.remitterName = name
                    })
                    .disposed(by: disposeBag)
            }
        }
        .onChange(of: viewModel.gateways, perform: { gateways in
            if !gateways.isEmpty, selectedGateway == nil {
                selectedGateway = viewModel.gateways.first
            }
        })
        .onChange(of: selectedGateway) { _ in
            if !amount.isEmpty {
                viewModel.verifyRemitInput(gateway: selectedGateway, remitterName: remitterName, remittance: amount)
            }
        }
        .onReceive(inspection.notice) {
           self.inspection.visit(self, $0)
        }
    }
    
    private var userGuide: some View {
        VStack(spacing: 0) {
            LimitSpacer(16)
            
            HStack(spacing: 0) {
                Text(Localize.string("jinyidigital_instructions_click_here"))
                    .localized(weight: .medium, size: 14, color: .redF20000)
                Image("iconChevronRightRed24")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .onTapGesture {
                userGuideOnTap()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
        }
    }
    
    private var remitInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("deposit_my_account_detail"))
                .localized(weight: .medium, size: 16, color: .gray9B9B9B)
            
            LimitSpacer(16)
            
            SwiftUIInputText(placeHolder: Localize.string("deposit_amount"), textFieldText: $amount, errorText: getAmountErrorText(), disablePaste: true, keyboardType: .numberPad)
                .id(Identifier.RemittanceInputTextField.rawValue)
            
            LimitSpacer(12)
            
            Text(selectedGateway == nil ? "" : String(format: Localize.string("deposit_offline_step1_tips"), selectedGateway!.cash.limitation.min.description(), selectedGateway!.cash.limitation.max.description()))
            .localized(weight: .medium, size: 14, color: .gray9B9B9B)
        }
        .padding(.horizontal, 30)
        .onChange(of: amount) { _ in
            viewModel.verifyRemitInput(gateway: selectedGateway, remitterName: remitterName, remittance: amount)
        }
    }
    
    private func getAmountErrorText() -> String? {
        let amountError =  viewModel.applicationErrors.filter { paymentError in
            paymentError is PaymentError.RemittanceIsEmpty || paymentError is PaymentError.RemittanceOutOfRange
        }
        
        guard !amountError.isEmpty else { return nil }
        if amountError.first! is PaymentError.RemittanceIsEmpty {
            return Localize.string("common_field_must_fill")
        } else if amountError.first! is PaymentError.RemittanceOutOfRange {
            return Localize.string("deposit_limitation_hint")
        } else {
            fatalError("Should not reach here.")
        }
    }
    
    private func isOnlineDataValid() -> Bool {
        !amount.isEmpty && viewModel.applicationErrors.isEmpty && selectedGateway != nil
    }
}

struct OnlinePaymentView_Previews: PreviewProvider {
    struct Preview: View {
        private let onlinePayment = PaymentsDTO.Online.init(
            identity: "24",
            name: "数字人民币",
            hint: "",
            isRecommend: false,
            beneficiaries: Single<NSArray>.just([
                PaymentsDTO.Gateway(identity: "70", name: "JinYi_Digital", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "200"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "2000")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true), PaymentsDTO.Gateway(identity: "20", name: "JinYi_Crypto", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "300"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "700")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)] as NSArray).asWrapper()
        )
        
        var body: some View {
            OnlinePaymentView(viewModel: OnlineDepositViewModel(selectedOnlinePayment: onlinePayment))
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
