import Foundation
import RxSwift
import SharedBu

protocol WithdrawalRepository {
    func getWithdrawalLimitation() -> Single<WithdrawalLimits>
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]>
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail>
    func getWithdrawalRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[WithdrawalRecord]>
    func cancelWithdrawal(ticketId: String) -> Completable
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getWithdrawalAccounts() -> Single<[FiatBankCard]>
    func addWithdrawalAccount(_ account: NewWithdrawalAccount) -> Completable
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String>
    func getCryptoBankCards() -> Single<[CryptoBankCard]>
    func addCryptoBankCard(currency: SupportCryptoType, alias: String, walletAddress: String, cryptoNetwork: CryptoNetwork) -> Single<String>
    func getCryptoLimitTransactions() -> Single<CpsWithdrawalSummary>
    func verifyCryptoBankCard(playerCryptoBankCardId: String, accountType: AccountType) -> Completable
    func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable
    func resendOtp(accountType: AccountType) -> Completable
    func getCryptoExchangeRate(_ cryptoCurrency: SupportCryptoType, _ supportLocale: SupportLocale) -> Single<IExchangeRate>
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: CryptoCurrency) -> Completable
    func deleteCryptoBankCard(id: String) -> Completable
    func getPlayerWithdrawalSystem() -> Single<WithdrawalSystem>
    func getIsAnyTicketApplying() -> Single<Bool>
}

class WithdrawalRepositoryImpl: WithdrawalRepository {
    private var bankApi: BankApi!
    private var imageApi: ImageApi!
    private var cpsApi: CPSApi!
    private var bankRepository: BankRepository!
    private var localStorageRepository: LocalStorageRepository!
    private let withdrawalSystem = WithdrawalSystem.create()
    
    init(_ bankApi: BankApi, imageApi: ImageApi, cpsApi: CPSApi, bankRepository: BankRepository!, localStorageRepository: LocalStorageRepository) {
        self.bankApi = bankApi
        self.imageApi = imageApi
        self.cpsApi = cpsApi
        self.bankRepository = bankRepository
        self.localStorageRepository = localStorageRepository
    }
    
    func deleteCryptoBankCard(id: String) -> Completable {
        let bankCardsMap = ["playerCryptoBankCardIds[0]": id]
        return cpsApi.deleteBankCards(bankCardId: bankCardsMap)
    }
    
    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        Single.zip(bankApi.getWithdrawalLimitation(), bankApi.getEachLimit(), bankApi.getTurnOver()).flatMap({ [unowned self] (daliyLimitsResponse, singleLimitsResponse, turnOverResponse) -> Single<WithdrawalLimits> in
            guard let daily = daliyLimitsResponse.data, let single = singleLimitsResponse.data, let turnOver = turnOverResponse.data else {
                return Single<WithdrawalLimits>.never()
            }
            let limits = WithdrawalLimits(dailyMaxCount: daily.withdrawalDailyCount, dailyMaxCash: daily.withdrawalDailyLimit.toAccountCurrency(), dailyCurrentCount: daily.withdrawalCount, dailyCurrentCash: daily.withdrawalLimit.toAccountCurrency(), singleCashMaximum: single.max.toAccountCurrency(), singleCashMinimum: single.minimum.toAccountCurrency(), turnoverAmount: turnOver.turnoverAmount.toAccountCurrency(), achievedAmount: turnOver.achievedAmount.toAccountCurrency(), unresolvedCryptoTurnover: self.sumOf(list: turnOver.cryptoWithdrawalRequestInfos))
            return Single<WithdrawalLimits>.just(limits)
        })
    }
    
    private func sumOf(list: [CryptoWithdrawalRequestInfo]?) -> AccountCurrency {
        guard let list = list else { return AccountCurrency.zero() }
        return list.map({ $0.withdrawalRequest.toAccountCurrency()}).reduce(AccountCurrency.zero()) { $0+$1 }
    }
    
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]> {
        let withdrawalRecord = bankApi.getWithdrawalRecords().map { (response) -> [WithdrawalRecordData] in
            guard let data = response.data else { return [] }
            let sortData = Array(data.sorted { $0.createdDate > $1.createdDate }.prefix(5))
            let noFloatingData = sortData.filter{ TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: $0.status) != TransactionStatus.floating }
            let floatingData = sortData.filter{ TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: $0.status) ==  TransactionStatus.floating }
            
            return floatingData + noFloatingData
        }.map {
            $0.map { (r) -> WithdrawalRecord in
                return self.convertWithdrawalDataToWithdrawalRecord(r)
            }
        }
        
        return withdrawalRecord
    }
    
    fileprivate func convertWithdrawalDataToWithdrawalRecord(_ r: WithdrawalRecordData) -> WithdrawalRecord {
        let createDate = r.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        return WithdrawalRecord(transactionTransactionType: TransactionType.Companion.init().convertTransactionType(transactionType_: r.ticketType), displayId: r.displayID,
                                transactionStatus: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: r.status),
                                createDate: createOffsetDateTime,
                                cashAmount: r.requestAmount.toAccountCurrency(),
                                isPendingHold: r.isPendingHold,
                                groupDay: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()))
    }
    
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail> {
        return bankApi.getWithdrawalRecordDetail(displayId: transactionId, ticketType: TransactionType.Companion.init().convertTransactionType(transactionType: transactionTransactionType)).flatMap { self.createWithdrawalRecordDetail(detail: $0.data!, transactionTransactionType: transactionTransactionType)
        }
    }
    
    func getWithdrawalRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[WithdrawalRecord]> {
        var statusDic: [String: Int32] = [:]
        status.enumerated().forEach { statusDic["ticketStatuses[\($0.0)]"] = TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus: $0.1)}
        return bankApi.getWithdrawalRecords(page: page, deteBegin: dateBegin.toDateStartTimeString(with: "-"), dateEnd: dateEnd.toDateStartTimeString(with: "-"), status: statusDic).map { (response) -> [WithdrawalRecord] in
            let data = response.data ?? []
            let sortedData = data.sorted(by: { $0.date > $1.date })
            var records: [WithdrawalRecord] = []
            for d in sortedData {
                for r in d.logs {
                    let record =  self.convertWithdrawalDataToWithdrawalRecord(r)
                    records.append(record)
                }
            }
            
            return records
        }
    }
    
    func cancelWithdrawal(ticketId: String) -> Completable {
        return bankApi.cancelWithdrawal(ticketId: ticketId)
    }
    
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: AccountCurrency) -> Single<String> {
        return bankApi.sendWithdrawalRequest(withdrawalRequest: WithdrawalRequest(requestAmount: cashAmount.bigAmount.doubleValue(exactRequired: false), playerBankCardId: playerBankCardId)).catchException(transferLogic: {
            switch $0 {
            case is PlayerWithdrawalDefective:
                return KtoPlayerWithdrawalDefective()
            default:
                return $0
            }
        }).map{ $0.data ?? ""}
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        let imageBindingData = UploadImagesData(ticketStatus: transactionId, images: portalImages.map { ImageBean(imageID: $0.imageId, fileName: $0.fileName) })
        
        return bankApi.bindingImageWithWithdrawalRecord(displayId: displayId, uploadImagesData: imageBindingData)
    }
    
    fileprivate func createWithdrawalRecordDetail(detail: WithdrawalRecordDetailData, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail> {
        return getStatusChangeHistories(statusChangeHistories: detail.statusChangeHistories).map { (tHistories) -> WithdrawalDetail in
            detail.toWithdrawalDetail(transactionTransactionType: transactionTransactionType, statusChangeHistories: tHistories)
        }
    }
    
    fileprivate func getStatusChangeHistories(statusChangeHistories: [StatusChangeHistory]) -> Single<[Transaction.StatusChangeHistory]> {
        var histories: [Single<Transaction.StatusChangeHistory>] = []
        for history in statusChangeHistories {
            histories.append(createStatusChangeHistory(changeHistory: history))
        }
        
        return Single.zip(histories)
    }
    
    fileprivate func createStatusChangeHistory(changeHistory: StatusChangeHistory) -> Single<Transaction.StatusChangeHistory> {
        var imgIDs: [Single<ResponseData<String>>] = []
        var portalImages: [PortalImage] = []
        let createDate = changeHistory.createdDate.convertDateTime() ?? Date()
        let createLocalDateTime = Kotlinx_datetimeLocalDateTime(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth(), hour: createDate.getHour(), minute: createDate.getMinute(), second: createDate.getSecond(), nanosecond: createDate.getNanosecond())
        let offsetDateTime = OffsetDateTime.Companion.init().create(localDateTime: createLocalDateTime, zoneId: TimeZone.current.identifier)
        for id in changeHistory.imageIDS {
            imgIDs.append(imageApi.getPrivateImageToken(imageId: id))
        }
        
        return Single.zip(imgIDs).map { (response) -> Transaction.StatusChangeHistory in
            for r in response {
                portalImages.append(PortalImage.Private(imageId: r.data ?? "", fileName: "", host: HttpClient().getHost()))
            }
            
            return Transaction.StatusChangeHistory(createdDate: offsetDateTime, imageIds: portalImages, remarkLevel1: changeHistory.remarkLevel1, remarkLevel2: changeHistory.remarkLevel2, remarkLevel3: changeHistory.remarkLevel3)
        }
    }
    
    func getWithdrawalAccounts() -> Single<[FiatBankCard]> {
        return Single<[FiatBankCard]>.zip(bankApi.getWithdrawalAccount(), bankRepository.getBankDictionary()) { [unowned self] (response, banks) in
            if let databeans = response.data?.payload {
                let data: [FiatBankCard] = databeans.map({ $0.toFiatBankCard(banks: banks, locale: self.localStorageRepository.getSupportLocal())

                })
                return data
            }
            return []
        }
    }
    
    func addWithdrawalAccount(_ account: NewWithdrawalAccount) -> Completable {
        let request = WithdrawalAccountAddRequest(bankID: account.bankId, bankName: account.bankName, branch: account.branch, accountName: account.accountName, accountNumber: account.accountNumber, address: account.address, city: account.city, location: account.location)
        return bankApi.isWithdrawalAccountExist(bankId: account.bankId, bankName: account.bankName, accountNumber: account.accountNumber).flatMapCompletable { (response) -> Completable in
            if let data = response.data, data {
                return Completable.error(KtoWithdrawalAccountExist())
            } else {
                return self.bankApi.sendWithdrawalAddAccount(request: request).asCompletable()
            }
        }
    }
    
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable {
        return bankApi.deleteWithdrawalAccount(playerBankCardId: playerBankCardId).asCompletable()
    }
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return cpsApi.getCryptoBankCard().map { (response) -> [CryptoBankCard] in
            guard let data = response.data?.payload else { return [] }
            return data.map{ $0.toCryptoBankCard() }
        }
    }
    
    func addCryptoBankCard(currency: SupportCryptoType, alias: String, walletAddress: String, cryptoNetwork: CryptoNetwork) -> Single<String> {
        let cryptoBankCardRequest = CryptoBankCardRequest(cryptoCurrency: currency.id__, cryptoWalletName: alias, cryptoWalletAddress: walletAddress, cryptoNetwork: cryptoNetwork.index)
        return self.cpsApi.createCryptoBankCard(cryptoBankCardRequest: cryptoBankCardRequest)
            .catchException(transferLogic: {
                switch $0 {
                case is PlayerCryptoBankCardIsExist:
                    return KtoWithdrawalAccountExist()
                default:
                    return $0
                }
            })
            .map { (response) -> String in
                guard let data = response.data else { return "" }
                return data
            }
    }
    
    func verifyCryptoBankCard(playerCryptoBankCardId: String, accountType: AccountType) -> Completable {
        cpsApi.sendAccountVerifyOTP(verifyRequest: AccountVerifyRequest(playerCryptoBankCardId: playerCryptoBankCardId, accountType: accountType.rawValue)).asCompletable()
    }
    
    func verifyOtp(verifyCode: String, accountType: AccountType) -> Completable {
        cpsApi.verifyOTP(verifyOtp: OTPVerifyRequest(verifyCode: verifyCode, accountType: accountType.rawValue)).asCompletable()
    }
    
    func resendOtp(accountType: AccountType) -> Completable {
        cpsApi.resendOTP(type: accountType.rawValue)
    }
    
    func getCryptoLimitTransactions() -> Single<CpsWithdrawalSummary> {
        return cpsApi.getCryptoWithdrawalLimitTransactions().map({ $0.data.toSummary() })
    }
    
    func getCryptoExchangeRate(_ cryptoCurrency: SupportCryptoType, _ supportLocale: SupportLocale) -> Single<IExchangeRate> {
        return cpsApi.getCryptoExchangeRate(cryptoCurrency.id__).map({ CryptoExchangeFactory.init().create(from: cryptoCurrency, to: supportLocale, exRate: "\($0.data)") })
    }
    
    func requestCryptoWithdrawal(playerCryptoBankCardId: String, requestCryptoAmount: Double, requestFiatAmount: Double, cryptoCurrency: CryptoCurrency) -> Completable {
        let currencyId = try! SupportCryptoType.companion.typeOf(cryptoCurrency: cryptoCurrency).id__
        let bean = CryptoWithdrawalRequest(playerCryptoBankCardId: playerCryptoBankCardId, requestCryptoAmount: requestCryptoAmount, requestFiatAmount: requestFiatAmount, cryptoCurrency: currencyId)
        return cpsApi.createCryptoWithdrawal(request: bean).catchException(transferLogic: {
            switch $0 {
            case is PlayerWithdrawalRequestCryptoRateChange:
                return KtoRequestCryptoRateChange()
            default:
                return $0
            }
        }).asCompletable()
    }
    
    func getPlayerWithdrawalSystem() -> Single<WithdrawalSystem> {
        return Single.just(withdrawalSystem)
    }
    
    func getIsAnyTicketApplying() -> Single<Bool> {
        return bankApi.getIsAnyTicketApplying().map { $0.data }
    }
}
