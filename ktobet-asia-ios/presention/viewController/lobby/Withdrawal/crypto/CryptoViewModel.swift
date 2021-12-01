import Foundation
import SharedBu
import RxSwift
import RxCocoa

class CryptoViewModel {
    
    private var withdrawalUseCase: WithdrawalUseCase!
    private var depositRepository: DepositRepository!
    private lazy var depositSystem = depositRepository.getPlayerDepositSystem()
    lazy var supportCryptoType = depositSystem.map({$0.supportCryptos()})
    
    init(withdrawalUseCase: WithdrawalUseCase, depositRepository: DepositRepository) {
        self.withdrawalUseCase = withdrawalUseCase
        self.depositRepository = depositRepository
    }
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return withdrawalUseCase.getCryptoBankCards()
    }
    
}
