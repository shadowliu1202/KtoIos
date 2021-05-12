import Foundation
import RxSwift
import share_bu

protocol WithdrawalRepository {
    func getWithdrawalLimitation() -> Single<WithdrawalLimits>
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]>
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail>
    func getWithdrawalRecords(page: String, dateBegin: String, dateEnd: String, status: [TransactionStatus]) -> Single<[WithdrawalRecord]>
    func cancelWithdrawal(ticketId: String) -> Completable
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getWithdrawalAccounts() -> Single<[WithdrawalAccount]>
    func addWithdrawalAccount(_ account: NewWithdrawalAccount) -> Completable
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: CashAmount) -> Single<String>
}

class WithdrawalRepositoryImpl: WithdrawalRepository {
    private var bankApi: BankApi!
    private var imageApi: ImageApi!
    
    init(_ bankApi: BankApi, imageApi: ImageApi) {
        self.bankApi = bankApi
        self.imageApi = imageApi
    }
    
    func getWithdrawalLimitation() -> Single<WithdrawalLimits> {
        Single.zip(bankApi.getWithdrawalLimitation(), bankApi.getEachLimit()).map { (daliyLimitsResponse, singleLimitsResponse) -> WithdrawalLimits in
            guard let daliyLimitsdata = daliyLimitsResponse.data, let singleLimitsData = singleLimitsResponse.data else {
                return WithdrawalLimits(dailyMaxCount: 0, dailyMaxCash: CashAmount(amount: 0), dailyCurrentCount: 0, dailyCurrentCash: CashAmount(amount: 0), singleCashMaximum: CashAmount(amount: 0), singleCashMinimum: CashAmount(amount: 0), turnoverAmount: CashAmount(amount: 0), achievedAmount: CashAmount(amount: 0), cryptoWithdrawalRequests: [])
            }
            
            return WithdrawalLimits(dailyMaxCount: daliyLimitsdata.withdrawalCount, dailyMaxCash: CashAmount(amount: daliyLimitsdata.withdrawalLimit), dailyCurrentCount: daliyLimitsdata.withdrawalDailyCount, dailyCurrentCash: CashAmount(amount: daliyLimitsdata.withdrawalDailyLimit), singleCashMaximum: CashAmount(amount: singleLimitsData.max), singleCashMinimum: CashAmount(amount: singleLimitsData.minimum), turnoverAmount: CashAmount(amount: 0), achievedAmount: CashAmount(amount: 0), cryptoWithdrawalRequests: [])
        }
    }
    
    func getWithdrawalRecords() -> Single<[WithdrawalRecord]> {
        let withdrawalRecord = bankApi.getWithdrawalRecords().map { (response) -> [WithdrawalRecordData] in
            guard let data = response.data else { return [] }
            let sortData = Array(data.sorted { $0.createdDate > $1.createdDate }.prefix(5))
            let noFloatingData = sortData.filter{ EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: $0.status) != TransactionStatus.floating }
            let floatingData = sortData.filter{ EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: $0.status) ==  TransactionStatus.floating }
            
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
        return WithdrawalRecord(transactionTransactionType: EnumMapper.Companion.init().convertTransactionType(transactionType_: r.ticketType), displayId: r.displayID,
                                transactionStatus: EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: r.status),
                                createDate: createOffsetDateTime,
                                cashAmount: CashAmount(amount: r.requestAmount),
                                isPendingHold: r.isPendingHold,
                                groupDay: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()))
    }
    
    func getWithdrawalRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<WithdrawalDetail> {
        return bankApi.getWithdrawalRecordDetail(displayId: transactionId, ticketType: EnumMapper.Companion.init().convertTransactionType(transactionType: transactionTransactionType)).flatMap { self.createWithdrawalRecordDetail(detail: $0.data!, transactionTransactionType: EnumMapper.Companion.init().convertTransactionType(transactionType: transactionTransactionType))
        }
    }
    
    func getWithdrawalRecords(page: String, dateBegin: String, dateEnd: String, status: [TransactionStatus]) -> Single<[WithdrawalRecord]> {
        var statusDic: [String: Int32] = [:]
        status.enumerated().forEach { statusDic["ticketStatuses[\($0.0)]"] = EnumMapper.Companion.init().convertTransactionStatus(transactionStatus: $0.1)}
        return bankApi.getWithdrawalRecords(page: page, deteBegin: dateBegin, dateEnd: dateEnd, status: statusDic).map { (response) -> [WithdrawalRecord] in
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
    
    func sendWithdrawalRequest(playerBankCardId: String, cashAmount: CashAmount) -> Single<String> {
        return bankApi.sendWithdrawalRequest(withdrawalRequest: WithdrawalRequest(requestAmount: cashAmount.amount, playerBankCardId: playerBankCardId)).map{ $0.data ?? ""}
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        let imageBindingData = UploadImagesData(ticketStatus: transactionId, images: portalImages.map { Image(imageID: $0.imageId, fileName: $0.fileName) })
        
        return bankApi.bindingImageWithWithdrawalRecord(displayId: displayId, uploadImagesData: imageBindingData)
    }
    
    fileprivate func createWithdrawalRecordDetail(detail: WithdrawalRecordDetailData, transactionTransactionType: Int32) -> Single<WithdrawalDetail> {
        let createDate = detail.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        let updateDate = detail.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()
        
        return getStatusChangeHistories(statusChangeHistories: detail.statusChangeHistories).map { (tHistories) -> WithdrawalDetail in
            let withdrawalRecord = WithdrawalRecord(transactionTransactionType: EnumMapper.Companion.init().convertTransactionType(transactionType_: transactionTransactionType), displayId: detail.displayId, transactionStatus: EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: detail.status), createDate: createOffsetDateTime, cashAmount: CashAmount(amount: detail.requestAmount), isPendingHold: detail.isPendingHold, groupDay: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()))
            return WithdrawalDetail.General.init(record: withdrawalRecord, isBatched: detail.isBatched, isPendingHold: detail.isPendingHold, statusChangeHistories: tHistories, updatedDate: updateOffsetDateTime)
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
    
    func getWithdrawalAccounts() -> Single<[WithdrawalAccount]> {
        return bankApi.getWithdrawalAccount().map({ (response: ResponseData<PayloadPage<WithdrawalAccountBean>>) -> [WithdrawalAccount] in
            if let databeans = response.data?.payload {
                let data: [WithdrawalAccount] = databeans.map {
                    WithdrawalAccount(accountName: $0.accountName, accountNumber: AccountNumber(value: $0.accountNumber), address: $0.address, bankId: Int32($0.bankID), bankName: $0.bankName, branch: $0.branch, city: $0.city, location: $0.location, playerBankCardId: $0.playerBankCardID, status: Int32($0.status), verifyStatus: PlayerBankCardVerifyStatus.Companion.init().create(status: Int32($0.verifyStatus)))
                }
                return data
            }
            return []
        })
    }
    
    func addWithdrawalAccount(_ account: NewWithdrawalAccount) -> Completable {
        let request = WithdrawalAccountAddRequest(bankID: account.bankId, bankName: account.bankName, branch: account.branch, accountName: account.accountName, accountNumber: account.accountNumber, address: account.address, city: account.city, location: account.location)
        return bankApi.sendWithdrawalAddAccount(request: request).asCompletable()
    }
    
    func deleteWithdrawalAccount(_ playerBankCardId: String) -> Completable {
        let parameters = ["playerBankCardIds[0]": playerBankCardId]
        return bankApi.deleteWithdrawalAccount(playerBankCardIdDict: parameters).asCompletable()
    }
}
