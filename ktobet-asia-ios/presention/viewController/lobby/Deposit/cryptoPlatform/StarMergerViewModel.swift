
import Foundation
import RxSwift
import RxCocoa
import SharedBu

class StarMergerViewModel: ObservableObject {
    @Published var amountRange: AmountRange? = nil
    @Published var paymentLink: CommonDTO.WebPath? = nil
    let depositService: IDepositAppService
    let disposeBag = DisposeBag()
    
    init(depositService: IDepositAppService) {
        self.depositService = depositService
        self.getGatewayInformation()
    }
    
    func getGatewayInformation() {
        RxSwift.Observable.from(depositService.getPayments()).first().flatMap({ paymentsDTO in
            return RxSwift.Single.from(paymentsDTO!.cryptoMarket!.beneficiaries)
        }).subscribe(onSuccess: { (gateway: PaymentsDTO.CryptoMarketGateway) in
            self.amountRange = gateway.amountRange
            self.paymentLink = gateway.paymentLink
        }, onError: { _ in
            
        }).disposed(by: disposeBag)
    }
}
