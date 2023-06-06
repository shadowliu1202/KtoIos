import Foundation
import RxSwift
import SharedBu

protocol WithdrawalUseCase {
  func getWithdrawalLimitation() -> Single<WithdrawalLimits>
  func getWithdrawalRecords() -> Single<[WithdrawalRecord]>
  func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail>
  func getWithdrawalRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus])
    -> Single<[WithdrawalRecord]>
  func cancelWithdrawal(ticketId: String) -> Completable
  func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
  func getWithdrawalAccounts() -> Single<[FiatBankCard]>
  func addWithdrawalAccount(_ newWithdrawalAccount: NewWithdrawalAccount) -> Completable
  func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable
  func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String>
  func getCryptoBankCards() -> Single<[CryptoBankCard]>
  func addCryptoBankCard(currency: SupportCryptoType, alias: String, walletAddress: String, cryptoNetwork: CryptoNetwork)
    -> Single<String>
  func getCryptoLimitTransactions() -> Single<CpsWithdrawalSummary>
  func sendCryptoOtpVerify(accountType: AccountType, playerCryptoBankCardId: String) -> Completable
  func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable
  func resendOtp(accountType: AccountType) -> Completable
  func getCryptoExchangeRate(_ cryptoCurrency: SupportCryptoType) -> Single<IExchangeRate>
  func requestCryptoWithdrawal(
    playerCryptoBankCardId: String,
    requestCryptoAmount: Double,
    requestFiatAmount: Double,
    cryptoCurrency: CryptoCurrency) -> Completable
  func deleteCryptoBankCard(id: String) -> Completable
  func getWithdrawalSystem() -> Single<WithdrawalSystem>
  func isAnyTicketApplying() -> Single<Bool>
  func getCryptoWithdrawalLimits(_ cryptoType: SupportCryptoType, _ cryptoNetwork: CryptoNetwork) -> Single<WithdrawalLimits>
  func isCryptoProcessCertified() -> Single<Bool>
}

class WithdrawalUseCaseImpl: WithdrawalUseCase {
  private var withdrawalRepository: WithdrawalRepository!
  private let localStorageRepo: LocalStorageRepository

  init(_ withdrawalRepository: WithdrawalRepository, _ localStorageRepo: LocalStorageRepository) {
    self.withdrawalRepository = withdrawalRepository
    self.localStorageRepo = localStorageRepo
  }

  func getCryptoWithdrawalLimits(_ cryptoType: SupportCryptoType, _ cryptoNetwork: CryptoNetwork) -> Single<WithdrawalLimits> {
    withdrawalRepository.getCryptoWithdrawalLimits(cryptoType: cryptoType, cryptoNetwork: cryptoNetwork)
  }

  func deleteCryptoBankCard(id: String) -> Completable {
    withdrawalRepository.deleteCryptoBankCard(id: id)
  }

  func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
    self.withdrawalRepository.getWithdrawalLimitation()
  }

  func getWithdrawalRecords() -> Single<[WithdrawalRecord]> {
    self.withdrawalRepository.getWithdrawalRecords()
  }

  func getWithdrawalRecordDetail(
    transactionId: String,
    transactionTransactionType: TransactionType) -> Single<WithdrawalDetail>
  {
    self.withdrawalRepository.getWithdrawalRecordDetail(
      transactionId: transactionId,
      transactionTransactionType: transactionTransactionType)
  }

  func getWithdrawalRecords(
    page: String,
    dateBegin: Date,
    dateEnd: Date,
    status: [TransactionStatus]) -> Single<[WithdrawalRecord]>
  {
    withdrawalRepository.getWithdrawalRecords(page: page, dateBegin: dateBegin, dateEnd: dateEnd, status: status)
  }

  func cancelWithdrawal(ticketId: String) -> Completable {
    self.withdrawalRepository.cancelWithdrawal(ticketId: ticketId)
  }

  func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String> {
    self.withdrawalRepository.sendWithdrawalRequest(playerBankCardId: playerBankCardId, cashAmount: cashAmount)
  }

  func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
    withdrawalRepository.bindingImageWithWithdrawalRecord(
      displayId: displayId,
      transactionId: transactionId,
      portalImages: portalImages)
  }

  func getWithdrawalAccounts() -> Single<[FiatBankCard]> {
    withdrawalRepository.getWithdrawalAccounts()
  }

  func addWithdrawalAccount(_ newWithdrawalAccount: NewWithdrawalAccount) -> Completable {
    withdrawalRepository.addWithdrawalAccount(newWithdrawalAccount)
  }

  func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable {
    withdrawalRepository.deleteWithdrawalAccount(playerBankCardId)
  }

  func getCryptoBankCards() -> Single<[CryptoBankCard]> {
    withdrawalRepository.getCryptoBankCards()
  }

  func addCryptoBankCard(
    currency: SupportCryptoType,
    alias: String,
    walletAddress: String,
    cryptoNetwork: CryptoNetwork) -> Single<String>
  {
    withdrawalRepository.addCryptoBankCard(
      currency: currency,
      alias: alias,
      walletAddress: walletAddress,
      cryptoNetwork: cryptoNetwork)
  }

  func getCryptoLimitTransactions() -> Single<CpsWithdrawalSummary> {
    withdrawalRepository.getCryptoLimitTransactions()
  }

  func sendCryptoOtpVerify(accountType: AccountType, playerCryptoBankCardId: String) -> Completable {
    withdrawalRepository.verifyCryptoBankCard(playerCryptoBankCardId: playerCryptoBankCardId, accountType: accountType)
  }

  func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable {
    withdrawalRepository.verifyOtp(verifyCode: verifyCode, accountType: accountType)
  }

  func resendOtp(accountType: AccountType) -> Completable {
    withdrawalRepository.resendOtp(accountType: accountType)
  }

  func getCryptoExchangeRate(_ cryptoCurrency: SupportCryptoType) -> Single<IExchangeRate> {
    withdrawalRepository.getCryptoExchangeRate(cryptoCurrency, self.localStorageRepo.getSupportLocale())
  }

  func requestCryptoWithdrawal(
    playerCryptoBankCardId: String,
    requestCryptoAmount: Double,
    requestFiatAmount: Double,
    cryptoCurrency: CryptoCurrency)
    -> Completable
  {
    withdrawalRepository.requestCryptoWithdrawal(
      playerCryptoBankCardId: playerCryptoBankCardId,
      requestCryptoAmount: requestCryptoAmount,
      requestFiatAmount: requestFiatAmount,
      cryptoCurrency: cryptoCurrency)
  }

  func getWithdrawalSystem() -> Single<WithdrawalSystem> {
    withdrawalRepository.getPlayerWithdrawalSystem()
  }

  func isAnyTicketApplying() -> Single<Bool> {
    withdrawalRepository.getIsAnyTicketApplying()
  }

  func isCryptoProcessCertified() -> Single<Bool> {
    withdrawalRepository.isCryptoProcessCertified()
  }
}
