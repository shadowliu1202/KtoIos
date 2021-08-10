import Foundation
import SharedBu
import RxSwift
import RxCocoa

class WithdrawalCryptoRequestViewModel {
    private var withdrawalUseCase: WithdrawalUseCase!
    private var playerUseCase : PlayerDataUseCase!
    private var localStorageRepository: LocalStorageRepository!
    lazy var localCurrency = localStorageRepository.getLocalCurrency()
   
    ///input
    var inputCryptoAmount: Decimal = 0 {
        didSet {
            self.rxCryptoAmount.onNext(inputCryptoAmount)
        }
    }
    private var rxCryptoAmount = PublishSubject<Decimal>()
    var inputFiatAmount: Decimal = 0 {
        didSet {
            self.rxFiatAmount.onNext(inputFiatAmount)
        }
    }
    private var rxFiatAmount = PublishSubject<Decimal>()
    private lazy var exchangeAmounts = Observable.combineLatest(rxCryptoAmount, rxFiatAmount)
    
    init(withdrawalUseCase: WithdrawalUseCase, playerUseCase: PlayerDataUseCase, localStorageRepository: LocalStorageRepository) {
        self.withdrawalUseCase = withdrawalUseCase
        self.playerUseCase = playerUseCase
        self.localStorageRepository = localStorageRepository
        
    }

    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        return self.withdrawalUseCase.getWithdrawalLimitation()
    }
    
    func getBalance() -> Single<CashAmount> {
        return self.playerUseCase.getBalance()
    }
    
    func cryptoCurrency(cryptoCurrency: Crypto) -> Single<CryptoExchangeRate> {
        return self.withdrawalUseCase.getCryptoExchangeRate(cryptoCurrency)
    }
    
    enum ValidError {
        case none
        case amountBeyondRange
        case amountBelowRange
        case amountExceedDailyLimit
        case notEnoughBalance
    }
    
    func withdrawalAmountValidation() -> Observable<ValidError> {
        return Observable.combineLatest(exchangeAmounts, getWithdrawalLimitation().asObservable(), getBalance().asObservable()).map { [weak self] (amounts, limitation, balance) -> ValidError in
            guard let `self` = self else {return .none }
            let cryptoAmount = amounts.0
            let fiatAmount = CashAmount(amount: amounts.1.doubleValue)
            if self.isAmountBeyond(fiatAmount, limitation) {
                return .amountBeyondRange
            } else if self.isAmountBelow(fiatAmount, limitation) || cryptoAmount == 0.0 {
                return .amountBelowRange
            } else if self.isAmountExceedDailyLimit(fiatAmount, limitation) {
                return .amountExceedDailyLimit
            } else if self.isBalanceNotEnough(fiatAmount, balance) {
                return .notEnoughBalance
            }
            return .none
        }
    }
    
    private func isAmountBeyond(_ amount: CashAmount, _ limitation: WithdrawalLimits) -> Bool {
        return amount > limitation.singleCashMaximum
    }
    
    private func isAmountBelow(_ amount: CashAmount, _ limitation: WithdrawalLimits) -> Bool {
        return amount < limitation.singleCashMinimum
    }
    
    private func isAmountExceedDailyLimit(_ amount: CashAmount, _ limitation: WithdrawalLimits) -> Bool {
        return amount > limitation.dailyMaxCash
    }
    
    private func isBalanceNotEnough(_ amount: CashAmount, _ balance: CashAmount) -> Bool {
        return amount > balance
    }
    
    lazy var withdrawalValidation: Observable<Bool> = Observable.combineLatest(self.withdrawalAmountValidation(), self.getWithdrawalLimitation().asObservable()).map({ (validError, limitation) in
        return validError == .none && limitation.dailyCurrentCount > 0
    }).startWith(false)
    
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: Crypto) -> Completable {
        return withdrawalUseCase.requestCryptoWithdrawal(playerCryptoBankCardId: playerCryptoBankCardId, requestCryptoAmount: requestCryptoAmount, requestFiatAmount: requestFiatAmount, cryptoCurrency: cryptoCurrency)
    }
}
