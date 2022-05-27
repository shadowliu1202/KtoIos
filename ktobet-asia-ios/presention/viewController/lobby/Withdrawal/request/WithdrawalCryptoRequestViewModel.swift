import Foundation
import SharedBu
import RxSwift
import RxCocoa

class WithdrawalCryptoRequestViewModel {
    private var withdrawalUseCase: WithdrawalUseCase!
    private var playerUseCase : PlayerDataUseCase!
    private var localStorageRepository: LocalStorageRepositoryImpl!
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
    private var cryptoType: SupportCryptoType!
    private var cryptoNetwork: CryptoNetwork!
    
    init(withdrawalUseCase: WithdrawalUseCase, playerUseCase: PlayerDataUseCase, localStorageRepository: LocalStorageRepositoryImpl) {
        self.withdrawalUseCase = withdrawalUseCase
        self.playerUseCase = playerUseCase
        self.localStorageRepository = localStorageRepository
    }

    func setCryptoType(cryptoType: SupportCryptoType, cryptoNetwork: CryptoNetwork) {
        self.cryptoType = cryptoType
        self.cryptoNetwork = cryptoNetwork
    }
    
    private func getCryptoWithdrawalLimits(_ cryptoType: SupportCryptoType, _ cryptoNetwork: CryptoNetwork) -> Single<WithdrawalLimits> {
        withdrawalUseCase.getCryptoWithdrawalLimits(cryptoType, cryptoNetwork)
    }

    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        return self.getCryptoWithdrawalLimits(self.cryptoType, self.cryptoNetwork)
    }
    
    func getBalance() -> Single<AccountCurrency> {
        return self.playerUseCase.getBalance()
    }
    
    func cryptoCurrency(cryptoCurrency: SupportCryptoType) -> Single<IExchangeRate> {
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
            let fiatAmount = self.fiatDecimalToAccountCurrency(amounts.1)
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
    
    private func isAmountBeyond(_ amount: AccountCurrency, _ limitation: WithdrawalLimits) -> Bool {
        return amount > limitation.singleCashMaximum
    }
    
    private func isAmountBelow(_ amount: AccountCurrency, _ limitation: WithdrawalLimits) -> Bool {
        return amount < limitation.singleCashMinimum
    }
    
    private func isAmountExceedDailyLimit(_ amount: AccountCurrency, _ limitation: WithdrawalLimits) -> Bool {
        return amount > limitation.dailyCurrentCash
    }
    
    private func isBalanceNotEnough(_ amount: AccountCurrency, _ balance: AccountCurrency) -> Bool {
        return amount > balance
    }
    
    lazy var withdrawalValidation: Observable<Bool> = Observable.combineLatest(self.withdrawalAmountValidation(), self.getWithdrawalLimitation().asObservable()).map({ (validError, limitation) in
        return validError == .none && limitation.dailyCurrentCount > 0
    }).startWith(false)
    
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: CryptoCurrency) -> Completable {
        return withdrawalUseCase.requestCryptoWithdrawal(playerCryptoBankCardId: playerCryptoBankCardId, requestCryptoAmount: requestCryptoAmount, requestFiatAmount: requestFiatAmount, cryptoCurrency: cryptoCurrency)
    }
    
    func fiatDecimalToAccountCurrency(_ de: Decimal) -> AccountCurrency {
        FiatFactory.init().create(supportLocale: self.localStorageRepository.getSupportLocale(), amount_: "\(de)")
    }
    
    func cryptoDecimalToCryptoCurrency(_ type: SupportCryptoType, _ de: Decimal) -> CryptoCurrency {
        CryptoFactory.init().create(supportCryptoType: type, amount_: "\(de)")
    }
    
    func getCryptoRequestBankCard(bankCardId: String) -> Single<CryptoBankCard?> {
        return withdrawalUseCase.getCryptoBankCards().map({$0.first(where: {$0.id_ == bankCardId})})
    }
}
