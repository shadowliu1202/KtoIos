import Foundation
import RxSwift
import SharedBu

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
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return withdrawalUseCase.getCryptoBankCards()
    }

}
