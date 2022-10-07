import RxSwift
import SharedBu

protocol OnlineDepositViewModelProtocol {
    var gateways: [PaymentsDTO.Gateway] { get }
    var applicationErrors: [PaymentError] { get }
    var selectedOnlinePayment: PaymentsDTO.Online { get }
    
    func getRemitterName() -> Single<String>
    func verifyRemitInput(gateway: PaymentsDTO.Gateway?, remitterName: String, remittance: String)
    func submitRemittance(gatewayIdentity: String, remitterName: String, remittance: String) -> Single<CommonDTO.WebPath>
}

class OnlineDepositViewModel: CollectErrorViewModel, OnlineDepositViewModelProtocol, ObservableObject {
    @Published private(set) var gateways: [PaymentsDTO.Gateway] = []
    @Published private(set) var applicationErrors: [PaymentError] = []
    
    let selectedOnlinePayment: PaymentsDTO.Online
    
    private let playerDataUseCase = DI.resolve(PlayerDataUseCase.self)!
    private let depositService = DI.resolve(ApplicationFactory.self)!.deposit()
    private let disposeBag = DisposeBag()
    
    init(selectedOnlinePayment: PaymentsDTO.Online) {
        self.selectedOnlinePayment = selectedOnlinePayment
        super.init()
        
        setupGateways()
    }
    
    private func setupGateways() {
        RxSwift.Single.from(selectedOnlinePayment.beneficiaries)
            .subscribe(onSuccess: { [unowned self] gateways in
                let gateways = gateways as! [PaymentsDTO.Gateway]
                self.gateways = gateways
            }).disposed(by: disposeBag)
    }
    
    func getRemitterName() -> Single<String> {
        playerDataUseCase.getPlayerRealName()
            .compose(self.applySingleErrorHandler())
    }
    
    func verifyRemitInput(gateway: PaymentsDTO.Gateway?, remitterName: String, remittance: String) {
        guard let gateway = gateway else { return }

        let remittance = remittance.isEmpty ? nil : remittance.replacingOccurrences(of: ",", with: "")
        let remitApplication =  RemitApplication(remitterName: remitterName, remitterAccount: "", remitterBankName: "",remittance: remittance, supportBankCode: "")
        
        applicationErrors = gateway.verifier.verify(target: remitApplication, isIgnoreNull: false)
    }
    
    func submitRemittance(gatewayIdentity: String, remitterName: String, remittance: String) -> Single<CommonDTO.WebPath> {
        let onlineRemitApplication = createOnlineRemitApplication(gatewayIdentity, remitterName, remittance)
        let onlineDepositDTO = OnlineDepositDTO.Request(paymentIdentity: selectedOnlinePayment.identity, application: onlineRemitApplication)
        
        return Single.from(self.depositService.requestOnlineDeposit(request: onlineDepositDTO))
            .observe(on: MainScheduler.instance)
    }
    
    private func createOnlineRemitApplication(_ gatewayIdentity: String, _ remitterName: String, _ remittance: String) -> OnlineRemitApplication {
        let onlineRemitter = OnlineRemitter(name: remitterName, account: "")
        let remittance = remittance.replacingOccurrences(of: ",", with: "")
        
        return OnlineRemitApplication(remitter: onlineRemitter, remittance: remittance, gatewayIdentity: gatewayIdentity, supportBankCode: nil)
    }
}
