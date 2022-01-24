import Foundation
import SharedBu
import RxSwift
import RxCocoa

class CryptoViewModel {
    
    private var withdrawalUseCase: WithdrawalUseCase!
    private var depositUseCase: DepositUseCase!
    private lazy var depositSystem = depositUseCase.getDepositSystem()
    private lazy var withdrawalSystem = withdrawalUseCase.getWithdrawalSystem()
    lazy var supportCryptoTypes = withdrawalSystem.map({$0.supportCryptos()})
    
    init(withdrawalUseCase: WithdrawalUseCase, depositUseCase: DepositUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
        self.depositUseCase = depositUseCase
    }
    
}
