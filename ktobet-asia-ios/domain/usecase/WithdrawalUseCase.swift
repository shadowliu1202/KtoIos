import Foundation
import SharedBu
import RxSwift

protocol WithdrawalUseCase {
    func getWithdrawalLimitation() -> Single<WithdrawalLimits>
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]>
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail>
    func getWithdrawalRecords(page: String, dateBegin: String, dateEnd: String, status: [TransactionStatus]) -> Single<[WithdrawalRecord]>
    func cancelWithdrawal(ticketId: String) -> Completable
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getWithdrawalAccounts() -> Single<[WithdrawalAccount]>
    func addWithdrawalAccount(_ newWithdrawalAccount: NewWithdrawalAccount) -> Completable
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: CashAmount) -> Single<String>
    func getCryptoBankCards() -> Single<[CryptoBankCard]>
    func addCryptoBankCard(currency: Crypto, alias: String, walletAddress: String) -> Single<String>
    func getCryptoLimitTransactions() -> Single<CryptoWithdrawalLimitLog>
    func sendCryptoOtpVerify(accountType: AccountType, playerCryptoBankCardId: String) -> Completable
    func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable
    func resendOtp(accountType: AccountType) -> Completable
    func getCryptoExchangeRate(_ cryptoCurrency: Crypto) -> Single<CryptoExchangeRate>
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: Crypto) -> Completable
    func deleteCryptoBankCard(id: String) -> Completable
}

class WithdrawalUseCaseImpl: WithdrawalUseCase {
    var withdrawalRepository : WithdrawalRepository!
    
    init(_ withdrawalRepository : WithdrawalRepository) {
        self.withdrawalRepository = withdrawalRepository
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
    
    func getWithdrawalRecords(page: String, dateBegin: String, dateEnd: String, status: [TransactionStatus]) -> Single<[WithdrawalRecord]> {
        return withdrawalRepository.getWithdrawalRecords(page: page, dateBegin: dateBegin, dateEnd: dateEnd, status: status)
    }
    
    func cancelWithdrawal(ticketId: String) -> Completable {
        return self.withdrawalRepository.cancelWithdrawal(ticketId: ticketId)
    }
    
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: CashAmount) -> Single<String> {
        return self.withdrawalRepository.sendWithdrawalRequest(playerBankCardId: playerBankCardId, cashAmount: cashAmount)
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        return withdrawalRepository.bindingImageWithWithdrawalRecord(displayId: displayId, transactionId: transactionId, portalImages: portalImages)
    }
    
    func getWithdrawalAccounts() -> Single<[WithdrawalAccount]> {
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
    
    func addCryptoBankCard(currency: Crypto, alias: String, walletAddress: String) -> Single<String> {
        return withdrawalRepository.addCryptoBankCard(currency: currency, alias: alias, walletAddress: walletAddress)
    }
    
    func getCryptoLimitTransactions() -> Single<CryptoWithdrawalLimitLog> {
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
    
    func getCryptoExchangeRate(_ cryptoCurrency: Crypto) -> Single<CryptoExchangeRate> {
        return withdrawalRepository.getCryptoExchangeRate(cryptoCurrency)
    }
    
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: Crypto) -> Completable {
        return withdrawalRepository.requestCryptoWithdrawal(playerCryptoBankCardId: playerCryptoBankCardId, requestCryptoAmount: requestCryptoAmount, requestFiatAmount: requestFiatAmount, cryptoCurrency: cryptoCurrency)
    }
}
