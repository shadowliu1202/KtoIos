import Foundation
import SharedBu
import RxSwift

protocol DepositUseCase {
    func requestCryptoDetailUpdate(displayId: String) -> Single<String>
    func getDepositSystem() -> Single<DepositSystem>
}

class DepositUseCaseImpl: DepositUseCase {
    var depositRepository : DepositRepository!
    
    init(_ depositRepository : DepositRepository) {
        self.depositRepository = depositRepository
    }
    
    //MARK: TODO 等withdrawl refactor 後移除
    func requestCryptoDetailUpdate(displayId: String) -> Single<String> {
        return depositRepository.requestCryptoDetailUpdate(displayId: displayId)
    }
        
    func getDepositSystem() -> Single<DepositSystem> {
        depositRepository.getPlayerDepositSystem()
    }
}
