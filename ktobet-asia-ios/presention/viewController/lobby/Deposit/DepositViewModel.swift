import Foundation
import RxSwift
import SharedBu
import RxCocoa

class DepositViewModel {
    private var depositService: IDepositAppService!
    private var depositUseCase: DepositUseCase!
    
    lazy var payments = RxSwift.Observable.from(depositService.getPayments())
    lazy var submitList = payments.map { paymentsDTO -> [DepositSelection] in
        var list: [DepositSelection] = []
        if let offline = paymentsDTO.offline,
           let crypto = paymentsDTO.crypto {
            list.append(OfflinePayment(offline))
            list.append(CryptoPayment(crypto))
            let online = paymentsDTO.fiat.compactMap { OnlinePayment($0) }
            list.append(contentsOf: online)
        }
        
        return list
    }
    
    //MARK: depositUseCase 等withdrawl refactor後移除
    init(_ depositService: IDepositAppService, depositUseCase: DepositUseCase) {
        self.depositService = depositService
        self.depositUseCase = depositUseCase
    }
    
    func requestCryptoDepositUpdate(displayId: String) -> Single<String> {
        depositUseCase.requestCryptoDetailUpdate(displayId: displayId)
    }
}
