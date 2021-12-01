import Foundation
import RxSwift
import RxCocoa
import SharedBu


class WithdrawalRequestViewModel {
    private var withdrawalUseCase: WithdrawalUseCase!
    private var playerDataUseCase: PlayerDataUseCase!
    
    var relayWithdrawalAmount = BehaviorRelay<String>(value: "")
    var relaydDailyMaxCount = BehaviorRelay<Int32>(value: 0)
    var relayDailyMaxCash = BehaviorRelay<AccountCurrency>(value: 0.toAccountCurrency())
    var singleCashMinimum: AccountCurrency?
    var singleCashMaximum: AccountCurrency?
    var relayNameEditable: Bool = false
    var balance: AccountCurrency?
    lazy var userName = playerDataUseCase.loadPlayer()
        .map{ $0.playerInfo.withdrawalName }
        .asObservable()
        
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
    
    func getBalance() -> Single<AccountCurrency> {
        self.playerDataUseCase.getBalance().do(onSuccess: {[weak self] (cashAmount) in
            self?.balance = cashAmount
        })
    }
    
    func event() -> (dailyCountValid: Observable<Bool>,
                     dailyCashValid: Observable<Bool>,
                     amountValid: Observable<AmountStatus>,
                     userNameValid: Observable<Bool>,
                     dataValid: Observable<Bool>) {
        let userNameValid = userName.map { $0.count != 0 }
        let dailyCountValid = relaydDailyMaxCount.map { $0 > 0 }
        let dailyCashValid = relayDailyMaxCash.map { $0.isPositive }
        let amountValid = relayWithdrawalAmount.map { [weak self] (amount) -> AmountStatus in
            if amount.count == 0 { return .empty}
            guard let singleCashMinimum = self?.singleCashMinimum,
                  let singleCashMaximum = self?.singleCashMaximum,
                  let dailyCurrentCash = self?.relayDailyMaxCash.value,
                  let balance = self?.balance
            else { return .invalid }
            let amount = amount.toAccountCurrency()
            if amount > singleCashMaximum { return .amountBeyondRange }
            if amount < singleCashMinimum { return .amountBelowRange }
            if amount > dailyCurrentCash { return .amountExceedDailyLimit}
            if amount > balance { return .notEnoughBalance}
            
            return .valid
        }
        
        let dataValid = Observable.combineLatest(dailyCountValid, dailyCashValid, amountValid, userNameValid) { $0 && $1 && $2 == .valid && $3 }
        
        return (dailyCountValid, dailyCashValid, amountValid, userNameValid, dataValid)
    }
    
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String> {
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
