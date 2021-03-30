import Foundation
import RxSwift
import share_bu

class WithdrawlLandingViewModel {
    private var withdrawalUseCase: WithdrawalUseCase!
    
    init(_ withdrawalUseCase: WithdrawalUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
    }
    
    func withdrawalAccounts() -> Single<[WithdrawalAccount]> {
        return self.withdrawalUseCase.getWithdrawalAccounts()
    }
    
    func deleteAccount(_ playerBankCardId: String) -> Completable {
        return self.withdrawalUseCase.deleteWithdrawalAccount(playerBankCardId)
    }
}
