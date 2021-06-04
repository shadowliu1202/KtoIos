import Foundation
import RxSwift
import SharedBu

protocol DepositRepository {
    func getDepositTypes() -> Single<[DepositRequest.DepositType]>
    func getDepositRecords() -> Single<[DepositRecord]>
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]>
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String>
    func getDepositMethods(depositType: Int32) -> Single<[DepositRequest.DepositTypeMethod]>
    func depositOnline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<DepositTransaction>
    func getDepositRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<DepositRecordDetail>
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getDepositRecords(page: String, dateBegin: String, dateEnd: String, status: [TransactionStatus]) -> Single<[DepositRecord]>
}

class DepositRepositoryImpl: DepositRepository {
    private var bankApi: BankApi!
    private var imageApi: ImageApi!
    
    init(_ bankApi: BankApi, imageApi: ImageApi) {
        self.bankApi = bankApi
        self.imageApi = imageApi
    }
    
    func getDepositTypes() -> Single<[DepositRequest.DepositType]> {
        let depositType = bankApi.getDepositTypes().map { (response) -> [DepositTypeData] in
            return response.data?.sorted { $0.depositTypeId < $1.depositTypeId } ?? []
        }.map {
            $0.map { (d) -> DepositRequest.DepositType in
                DepositRequest.DepositTypeCompanion.init().create(id: d.depositTypeId, name: d.depositTypeName, min: CashAmount(amount: d.depositLimitMinimum), max: CashAmount(amount: d.depositLimitMaximum), isFavorite: d.isFavorite)
            }
        }
        
        return depositType
    }
    
    func getDepositRecords() -> Single<[DepositRecord]> {
        let depositRecord = bankApi.getDepositRecords().map { (response) -> [DepositRecordData] in
            guard let data = response.data else { return [] }
            let sortData = Array(data.sorted { $0.createdDate > $1.createdDate }.prefix(5))
            let noFloatingData = sortData.filter{ EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: $0.status) != TransactionStatus.floating }
            let floatingData = sortData.filter{ EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: $0.status) ==  TransactionStatus.floating }
            
            return floatingData + noFloatingData
        }.map {
            $0.map { (r) -> DepositRecord in
                return self.convertDepositDataToDepositRecord(r)
            }
        }
        
        return depositRecord
    }
    
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]> {
        Single.zip(bankApi.getBanks(), bankApi.getDepositOfflineBankAccounts()).map { (simpleBankResponse, depositOfflineBankAccountsResponse) -> [FullBankAccount] in
            guard let offline = depositOfflineBankAccountsResponse.data?.paymentGroupPaymentCards.values, let banks = simpleBankResponse.data else {
                return []
            }
            
            var fullBankAccounts: [FullBankAccount] = []
            for o in offline {
                for b in banks {
                    if o.bankID == b.bankId {
                        let fullAccount = FullBankAccount(bank: Bank(bankId: o.bankID, name: b.name, shortName: b.shortName), bankAccount: BankAccount(accountName: o.accountName, accountNumber: o.accountNumber, bankId: o.bankID, branch: o.branch, paymentTokenId: o.paymentTokenID))
                        fullBankAccounts.append(fullAccount)
                        break
                    }
                }
            }
            
            return fullBankAccounts
        }
    }
    
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String> {
        let request = DepositOfflineBankAccountsRequest(paymentTokenID: depositRequest.paymentToken, requestAmount: String(depositRequest.cashAmount.amount), remitterAccountNumber: depositRequest.remitter.accountNumber, remitter: depositRequest.remitter.name, remitterBankName: depositRequest.remitter.bankName, channel: 0, depositType: depositTypeId)
        return bankApi.depositOffline(depositRequest: request).map { (response) -> String in
            return response.data ?? ""
        }
    }
    
    func depositOnline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<DepositTransaction> {
        let request = DepositOnlineAccountsRequest(paymentTokenID: depositRequest.paymentToken, requestAmount: String(depositRequest.cashAmount.amount), remitter: depositRequest.remitter.name, channel: 0, remitterAccountNumber: depositRequest.remitter.accountNumber, remitterBankName: depositRequest.remitter.bankName, depositType: depositTypeId)
        return bankApi.depositOnline(depositRequest: request).map { (response) -> DepositTransaction in
            guard let data = response.data else {
                return DepositTransaction(id: "", provider: "", transactionId: "", bankId: "")
            }
            
            let transactionData = DepositTransaction(id: data.displayID, provider: data.providerAccountID, transactionId: data.depositTransactionID, bankId: String(data.bankID ?? 0))
            return transactionData
        }
    }
    
    func getDepositMethods(depositType: Int32) -> Single<[DepositRequest.DepositTypeMethod]> {
        let depositMethod = bankApi.getDepositMethods(depositType: depositType).map { (response) -> [DepositMethodData] in
            return response.data ?? []
        }.map {
            $0.map { (m) -> DepositRequest.DepositTypeMethod in
                DepositRequest.DepositTypeMethod(depositLimitMaximum: m.depositLimitMaximum, depositLimitMinimum: m.depositLimitMinimum, depositMethodId: m.depositMethodID, depositTypeId: m.depositTypeID, depositTypeName: m.depositTypeName, displayName: m.displayName, isFavorite: m.isFavorite, paymentTokenId: m.paymentTokenID)
            }
        }
        
        return depositMethod
    }
    
    func getDepositRecordDetail(transactionId: String, transactionTransactionType: TransactionType) -> Single<DepositRecordDetail> {
        return bankApi.getDepositRecordDetail(displayId: transactionId, ticketType: EnumMapper.Companion.init().convertTransactionType(transactionType: transactionTransactionType)).flatMap { self.createDepositRecordDetail(detail: $0.data!)
        }
    }
    
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        let imageBindingData = UploadImagesData(ticketStatus: transactionId, images: portalImages.map { Image(imageID: $0.imageId, fileName: $0.fileName) })
        
        return bankApi.bindingImageWithDepositRecord(displayId: displayId, uploadImagesData: imageBindingData)
    }
    
    func getDepositRecords(page: String, dateBegin: String, dateEnd: String, status: [TransactionStatus]) -> Single<[DepositRecord]> {
        var statusDic: [String: Int32] = [:]
        status.enumerated().forEach { statusDic["ticketStatuses[\($0.0)]"] = EnumMapper.Companion.init().convertTransactionStatus(transactionStatus: $0.1)}
        return bankApi.getDepositRecords(page: page, deteBegin: dateBegin, dateEnd: dateEnd, status: statusDic).map { (response) -> [DepositRecord] in
            let data = response.data ?? []
            let sortedData = data.sorted(by: { $0.date > $1.date })
            var records: [DepositRecord] = []
            for d in sortedData {
                for r in d.logs {
                    let record =  self.convertDepositDataToDepositRecord(r)
                    records.append(record)
                }
            }
            
            return records
        }
    }
    
    fileprivate func createDepositRecordDetail(detail: DepositRecordDetailData) -> Single<DepositRecordDetail> {
        let createDate = detail.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        let updateDate = detail.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()

        return getStatusChangeHistories(statusChangeHistories: detail.statusChangeHistories).map { (tHistories) -> DepositRecordDetail in
            DepositRecordDetail(createdDate: createOffsetDateTime, displayId: detail.displayID, isPendingHold: detail.isPendingHold, remark: "", requestAmount: CashAmount(amount: detail.requestAmount), status: EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: detail.status), statusChangeHistories: tHistories, updatedDate: updateOffsetDateTime)
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

    fileprivate func convertDepositDataToDepositRecord(_ r: DepositRecordData) -> DepositRecord {
        let createDate = r.createdDate.convertDateTime() ?? Date()
        let createOffsetDateTime = createDate.convertDateToOffsetDateTime()
        let updateDate = r.updatedDate.convertDateTime() ?? Date()
        let updateOffsetDateTime = updateDate.convertDateToOffsetDateTime()
        return DepositRecord(displayId: r.displayId,
                             transactionTransactionType: EnumMapper.Companion.init().convertTransactionType(transactionType_: r.ticketType),
                             transactionStatus: EnumMapper.Companion.init().convertTransactionStatus(ticketStatus: r.status),
                             actualAmount: CashAmount(amount: r.actualAmount),
                             createdDate: createOffsetDateTime,
                             isFee: r.isFee, isPendingHold: r.isPendingHold,
                             requestAmount: CashAmount(amount: r.requestAmount),
                             updatedDate: updateOffsetDateTime,
                             groupDay: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()))
    }
}
