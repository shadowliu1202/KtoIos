import SwiftUI
import SharedBu
import RxSwift

struct OnlinePaymentView: View {
    @StateObject var viewModel: OnlineDepositViewModel
    
    @State private var remitterName: String = ""
    @State private var amount: String = ""
    @State private var submitInProgress = false
    
    var userGuideOnTap = {}
    var remitButtonOnSuccess = { (webPath: CommonDTO.WebPath) in }
    
    private let disposeBag = DisposeBag()
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    Text(viewModel.selectedOnlinePayment.name)
                        .customizedFont(fontWeight: .semibold, size: 24, color: .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                    
                    if let selectedGateway = viewModel.selectedGateway, selectedGateway.isInstructionDisplayed {
                        userGuide
                    }
                    
                    LimitSpacer(30)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Localize.string("deposit_select_method"))
                            .customizedFont(fontWeight: .medium, size: 16, color: .primaryGray)
                            .padding(.horizontal, 30)
                        
                        PickList(selectedItem: $viewModel.selectedGateway, items: viewModel.gateways)
                    }
                    
                    LimitSpacer(30)
                    
                    remitInfo
                    
                    LimitSpacer(40)
                    
                    Button {
                        viewModel.submitRemittance(paymentIdentity: viewModel.selectedOnlinePayment.identity)
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
                }
            }
        }
        .pageBackgroundColor(.defaultGray)
        .onAppear {
            if remitterName.isEmpty {
                viewModel.getRemitterName()
                    .subscribe(onSuccess: { name in
                        self.remitterName = name
                    })
                    .disposed(by: disposeBag)
            }
            
            if viewModel.selectedGateway == nil {
                viewModel.setupDefaultSelectedGateway()
            }
        }
        .onChange(of: viewModel.selectedGateway) { _ in
            if !amount.isEmpty {
                viewModel.createVerifiedRemitApplication(gateway: viewModel.selectedGateway!, remitterName: remitterName, remittance: amount)
            }
        }
    }
    
    private var userGuide: some View {
        VStack(spacing: 0) {
            LimitSpacer(16)
            
            HStack(spacing: 0) {
                Text(Localize.string("jinyidigital_instructions_click_here"))
                    .customizedFont(fontWeight: .medium, size: 14, color: .primaryRed)
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
                .customizedFont(fontWeight: .medium, size: 16, color: .primaryGray)
            
            LimitSpacer(16)
            
            SwiftUIInputText(placeHolder: Localize.string("deposit_amount"), textFieldText: $amount, errorText: getAmountErrorText(), keyboardType: .numberPad)
            
            LimitSpacer(12)
            
            Text(viewModel.selectedGateway == nil ? "" : String(format: Localize.string("deposit_offline_step1_tips"), viewModel.selectedGateway!.cash.limitation.min.description(), viewModel.selectedGateway!.cash.limitation.max.description()))
            .customizedFont(fontWeight: .medium, size: 14, color: .primaryGray)
        }
        .padding(.horizontal, 30)
        .onChange(of: amount) { _ in
            viewModel.createVerifiedRemitApplication(gateway: viewModel.selectedGateway!, remitterName: remitterName, remittance: amount)
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
            fatalError()
        }
    }
    
    private func isOnlineDataValid() -> Bool {
        !amount.isEmpty && viewModel.applicationErrors.isEmpty && viewModel.selectedGateway != nil
    }
}

struct OnlinePaymentViewPreviews: View {
    private let onlinePayment = PaymentsDTO.Online.init(identity: "24", name: "数字人民币", hint: "", isRecommend: false, beneficiaries: Single<NSArray>.just([PaymentsDTO.Gateway(identity: "70", name: "JinYi_Digital", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "200"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "2000")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true), PaymentsDTO.Gateway(identity: "20", name: "JinYi_Crypto", cash: CashType.Input.init(limitation: AmountRange.init(min: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "300"), max: FiatFactory.shared.create(supportLocale: SupportLocale.China.init(), amount_: "700")), isFloatAllowed: false), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)] as NSArray).asNSArray())
    
    var body: some View {
        OnlinePaymentView(viewModel: OnlineDepositViewModel(selectedOnlinePayment: onlinePayment))
    }
}

struct OnlinePaymentView_Previews: PreviewProvider {
    static var previews: some View {
        OnlinePaymentViewPreviews()
    }
}
