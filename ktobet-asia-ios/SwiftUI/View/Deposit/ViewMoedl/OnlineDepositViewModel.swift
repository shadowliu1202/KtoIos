import RxSwift
import SharedBu

class OnlineDepositViewModel: KTOViewModel, ObservableObject {
    @Published var selectedGateway: PaymentsDTO.Gateway? = nil
    
    @Published private(set) var gateways: [PaymentsDTO.Gateway] = []
    @Published private(set) var applicationErrors: [PaymentError] = []
    
    var remitApplication: OnlineRemitApplication!
    
    let selectedOnlinePayment: PaymentsDTO.Online
    
    private let playerDataUseCase = DI.resolve(PlayerDataUseCase.self)!
    private let depositService = DI.resolve(ApplicationFactory.self)!.deposit()
    private let disposeBag = DisposeBag()
    
    init(selectedOnlinePayment: PaymentsDTO.Online) {
        self.selectedOnlinePayment = selectedOnlinePayment
    }
    
    func setupDefaultSelectedGateway() {
        RxSwift.Single.from(selectedOnlinePayment.beneficiaries).subscribe(onSuccess: { [unowned self] gateways in
            let gateways = gateways as! [PaymentsDTO.Gateway]
            self.gateways = gateways
            self.selectedGateway = gateways.first
        }).disposed(by: disposeBag)
    }
    
    func getRemitterName() -> Single<String> {
        playerDataUseCase.getPlayerRealName()
            .compose(self.applySingleErrorHandler())
    }
    
    func createVerifiedRemitApplication(gateway: PaymentsDTO.Gateway, remitterName: String, remittance: String) {
        let remittance = remittance.isEmpty ? nil : remittance.replacingOccurrences(of: ",", with: "")
        verifiedRemitApplication(gateway, remitterName, remittance)
        
        if applicationErrors.isEmpty {
            createRemitApplication(gatewayIdentity: gateway.identity, remitterName, remittance!)
        }
    }
    
    private func verifiedRemitApplication(_ gateway: PaymentsDTO.Gateway, _ remitterName: String, _ remittance: String?) {
        let remitApplication =  RemitApplication(remitterName: remitterName, remitterAccount: "", remitterBankName: "",remittance: remittance, supportBankCode: "")
        applicationErrors = gateway.verifier.verify(target: remitApplication, isIgnoreNull: false)
    }
    
    private func createRemitApplication(gatewayIdentity: String, _ remitterName: String, _ remittance: String) {
        let onlineRemitter =  OnlineRemitter(name: remitterName, account: "")
        remitApplication = OnlineRemitApplication(remitter: onlineRemitter, remittance: remittance, gatewayIdentity: gatewayIdentity, supportBankCode: nil)
    }
    
    func submitRemittance(paymentIdentity: String) -> Single<CommonDTO.WebPath> {
        let onlineDepositDTO = OnlineDepositDTO.Request(paymentIdentity: paymentIdentity, application: remitApplication)
        
        return Single.from(self.depositService.requestOnlineDeposit(request: onlineDepositDTO))
            .observe(on: MainScheduler.instance)
    }
}
