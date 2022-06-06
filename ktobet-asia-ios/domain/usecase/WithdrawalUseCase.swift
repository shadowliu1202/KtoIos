import Foundation
import SharedBu
import RxSwift

protocol WithdrawalUseCase {
    func getWithdrawalLimitation() -> Single<WithdrawalLimits>
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]>
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail>
    func getWithdrawalRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[WithdrawalRecord]>
    func cancelWithdrawal(ticketId: String) -> Completable
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getWithdrawalAccounts() -> Single<[FiatBankCard]>
    func addWithdrawalAccount(_ newWithdrawalAccount: NewWithdrawalAccount) -> Completable
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String>
    func getCryptoBankCards() -> Single<[CryptoBankCard]>
    func addCryptoBankCard(currency: SupportCryptoType, alias: String, walletAddress: String, cryptoNetwork: CryptoNetwork) -> Single<String>
    func getCryptoLimitTransactions() -> Single<CpsWithdrawalSummary>
    func sendCryptoOtpVerify(accountType: AccountType, playerCryptoBankCardId: String) -> Completable
    func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable
    func resendOtp(accountType: AccountType) -> Completable
    func getCryptoExchangeRate(_ cryptoCurrency: SupportCryptoType) -> Single<IExchangeRate>
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: CryptoCurrency) -> Completable
    func deleteCryptoBankCard(id: String) -> Completable
    func getWithdrawalSystem() -> Single<WithdrawalSystem>
    func isAnyTicketApplying() -> Single<Bool>
    func getCryptoWithdrawalLimits(_ cryptoType: SupportCryptoType, _ cryptoNetwork: CryptoNetwork) -> Single<WithdrawalLimits>
    func isCryptoProcessCertified() -> Single<Bool>
}

class WithdrawalUseCaseImpl: WithdrawalUseCase {
    private var withdrawalRepository : WithdrawalRepository!
    private let localStorageRepo: PlayerLocaleConfiguration
    
    init(_ withdrawalRepository : WithdrawalRepository, _ localStorageRepo: PlayerLocaleConfiguration) {
        self.withdrawalRepository = withdrawalRepository
        self.localStorageRepo = localStorageRepo
    }

    func getCryptoWithdrawalLimits(_ cryptoType: SupportCryptoType, _ cryptoNetwork: CryptoNetwork) -> Single<WithdrawalLimits> {
        withdrawalRepository.getCryptoWithdrawalLimits(cryptoType: cryptoType, cryptoNetwork: cryptoNetwork)
    }
    
    func deleteCryptoBankCard(id: String) -> Completable {
        return withdrawalRepository.deleteCryptoBankCard(id: id)
    }
    
    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        return self.withdrawalRepository.getWithdrawalLimitation()
    }
    
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]> {
        return self.withdrawalRepository.getWithdrawalRecords()
    }
    
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail> {
        return self.withdrawalRepository.getWithdrawalRecordDetail(transactionId: transactionId, transactionTransactionType: transactionTransactionType)
    }
    
    func getWithdrawalRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[WithdrawalRecord]> {
        return withdrawalRepository.getWithdrawalRecords(page: page, dateBegin: dateBegin, dateEnd: dateEnd, status: status)
    }
    
    func cancelWithdrawal(ticketId: String) -> Completable {
        return self.withdrawalRepository.cancelWithdrawal(ticketId: ticketId)
    }
    
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String> {
        return self.withdrawalRepository.sendWithdrawalRequest(playerBankCardId: playerBankCardId, cashAmount: cashAmount)
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return withdrawalRepository.bindingImageWithWithdrawalRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
    
    func getWithdrawalAccounts() -> Single<[FiatBankCard]> {
        return withdrawalRepository.getWithdrawalAccounts()
    }
    
    func addWithdrawalAccount(_ newWithdrawalAccount: NewWithdrawalAccount) -> Completable {
        return withdrawalRepository.addWithdrawalAccount(newWithdrawalAccount)
    }
    
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable {
        return withdrawalRepository.deleteWithdrawalAccount(playerBankCardId)
    }
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return withdrawalRepository.getCryptoBankCards()
    }
    
    func addCryptoBankCard(currency: SupportCryptoType, alias: String, walletAddress: String, cryptoNetwork: CryptoNetwork) -> Single<String> {
        return withdrawalRepository.addCryptoBankCard(currency: currency, alias: alias, walletAddress: walletAddress, cryptoNetwork: cryptoNetwork)
    }
    
    func getCryptoLimitTransactions() -> Single<CpsWithdrawalSummary> {
        return withdrawalRepository.getCryptoLimitTransactions()
    }
    
    func sendCryptoOtpVerify(accountType: AccountType, playerCryptoBankCardId: String) -> Completable {
        return withdrawalRepository.verifyCryptoBankCard(playerCryptoBankCardId: playerCryptoBankCardId, accountType: accountType)
    }
    
    func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable {
        withdrawalRepository.verifyOtp(verifyCode: verifyCode, accountType: accountType)
    }
    
    func resendOtp(accountType: AccountType) -> Completable {
        withdrawalRepository.resendOtp(accountType: accountType)
    }
    
    func getCryptoExchangeRate(_ cryptoCurrency: SupportCryptoType) -> Single<IExchangeRate> {
        return withdrawalRepository.getCryptoExchangeRate(cryptoCurrency, self.localStorageRepo.getSupportLocale())
    }
    
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: CryptoCurrency) -> Completable {
        return withdrawalRepository.requestCryptoWithdrawal(playerCryptoBankCardId: playerCryptoBankCardId, requestCryptoAmount: requestCryptoAmount, requestFiatAmount: requestFiatAmount, cryptoCurrency: cryptoCurrency)
    }
    
    func getWithdrawalSystem() -> Single<WithdrawalSystem> {
        return withdrawalRepository.getPlayerWithdrawalSystem()
    }
    
    func isAnyTicketApplying() -> Single<Bool> {
        return withdrawalRepository.getIsAnyTicketApplying()
    }
    
    func isCryptoProcessCertified() -> Single<Bool> {
        return withdrawalRepository.isCryptoProcessCertified()
    }
}
