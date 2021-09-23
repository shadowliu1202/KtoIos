import Foundation
import RxSwift
import RxCocoa
import SharedBu


class WithdrawalRequestViewModel {
    private var withdrawalUseCase: WithdrawalUseCase!
    private var playerDataUseCase: PlayerDataUseCase!
    
    var relayWithdrawalAmount = BehaviorRelay<String>(value: "")
    var relayName = BehaviorRelay<String>(value: "")
    var relaydDailyMaxCount = BehaviorRelay<Int32>(value: 0)
    var relayDailyMaxCash = BehaviorRelay<CashAmount>(value: CashAmount(amount: 0))
    var singleCashMinimum: CashAmount?
    var singleCashMaximum: CashAmount?
    var relayNameEditable: Bool = false
    var balance: CashAmount?
        
    init(withdrawalUseCase: WithdrawalUseCase, playerDataUseCase: PlayerDataUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
        self.playerDataUseCase = playerDataUseCase
    }
    
    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        return self.withdrawalUseCase.getWithdrawalLimitation().do(onSuccess:{[weak self] (limits) in
            self?.singleCashMinimum = limits.singleCashMinimum
            self?.singleCashMaximum = limits.singleCashMaximum
            self?.relaydDailyMaxCount.accept(limits.dailyMaxCount)
            self?.relayDailyMaxCash.accept(limits.dailyMaxCash)
        })
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerDataUseCase.isRealNameEditable().do(onSuccess: {[weak self] (editable) in
            self?.relayNameEditable = editable
        })
    }
    
    func getBalance() -> Single<CashAmount> {
        self.playerDataUseCase.getBalance().do(onSuccess: {[weak self] (cashAmount) in
            self?.balance = cashAmount
        })
    }
    
    func event() -> (dailyCountValid: Observable<Bool>,
                     dailyCashValid: Observable<Bool>,
                     amountValid: Observable<AmountStatus>,
                     userNameValid: Observable<Bool>,
                     dataValid: Observable<Bool>) {
        let userNameValid = relayName.map { $0.count != 0 }
        let dailyCountValid = relaydDailyMaxCount.map { $0 >= 0 }
        let dailyCashValid = relayDailyMaxCash.map { $0.amount >= 0}
        let amountValid = relayWithdrawalAmount.map { [weak self] (amount) -> AmountStatus in
            if amount.count == 0 { return .empty}
            guard let amount = amount.currencyAmountToDouble(),
                  let singleCashMinimum = self?.singleCashMinimum,
                  let singleCashMaximum = self?.singleCashMaximum,
                  let dailyCurrentCash = self?.relayDailyMaxCash.value,
                  let balance = self?.balance
            else { return .invalid }
            if amount > singleCashMaximum.amount { return .amountBeyondRange }
            if amount < singleCashMinimum.amount { return .amountBelowRange }
            if amount > dailyCurrentCash.amount { return .amountExceedDailyLimit}
            if amount > balance.amount { return .notEnoughBalance}
            
            return .valid
        }
        
        let dataValid = Observable.combineLatest(dailyCountValid, dailyCashValid, amountValid, userNameValid) { $0 && $1 && $2 == .valid && $3 }
        
        return (dailyCountValid, dailyCashValid, amountValid, userNameValid, dataValid)
    }
    
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: CashAmount) -> Single<String> {
        return withdrawalUseCase.sendWithdrawalRequest(playerBankCardId: playerBankCardId, cashAmount: cashAmount)
    }
    
    enum AmountStatus {
        case amountBeyondRange
        case notEnoughBalance
        case amountBelowRange
        case amountExceedDailyLimit
        case invalid
        case valid
        case empty
    }
}
