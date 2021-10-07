import Foundation
import RxSwift
import SharedBu

protocol DepositRepository {
    func getDepositTypes() -> Single<[DepositType]>
    func getDepositRecords() -> Single<[DepositRecord]>
    func getDepositOfflineBankAccounts() -> Single<[FullBankAccount]>
    func depositOffline(depositRequest: DepositRequest, depositTypeId: Int32) -> Single<String>
    func getDepositMethods(depositType: Int32) -> Single<[PaymentGateway]>
    func depositOnline(remitter: DepositRequest_.Remitter, paymentTokenId: String, depositAmount: CashAmount, providerId: Int32, depositTypeId: Int32) -> Single<DepositTransaction>
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail>
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable
    func getDepositRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[DepositRecord]>
    func requestCryptoDeposit() -> Single<String>
    func requestCryptoDetailUpdate(displayId: String) -> Single<String>
}

class DepositRepositoryImpl: DepositRepository {
    private var bankApi: BankApi!
    private var imageApi: ImageApi!
    private var cpsApi: CPSApi!
    let MOBILE_CHANNEL = 0
    
    init(_ bankApi: BankApi, imageApi: ImageApi, cpsApi: CPSApi) {
        self.bankApi = bankApi
        self.imageApi = imageApi
        self.cpsApi = cpsApi
    }
    
    func getDepositTypes() -> Single<[DepositType]> {
        let depositType = bankApi.getDepositTypes().map { (response) -> [DepositTypeData] in
            return response.data?.sorted { $0.depositTypeId < $1.depositTypeId } ?? []
        }.map {
            $0.map { (d) -> DepositType in
                DepositType(id: d.depositTypeId, name: d.depositTypeName, min: CashAmount(amount: d.depositLimitMinimum), max: CashAmount(amount: d.depositLimitMaximum), isFavorite: d.isFavorite)
            }
        }
        
        return depositType
    }
    
    func getDepositRecords() -> Single<[DepositRecord]> {
        let depositRecord = bankApi.getDepositRecords().map { (response) -> [DepositRecord] in
            guard let data = response.data else { return [] }
            let sortingData = data.map{ self.convertDepositDataToDepositRecord($0) }.sorted { $0.createdDate.toDateTimeString() > $1.createdDate.toDateTimeString() }
            let floatingData = sortingData.filter{ $0.transactionStatus == .floating }
            let notFloatingData = sortingData.filter{ $0.transactionStatus != .floating }
            return floatingData + notFloatingData
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
    
    func depositOnline(remitter: DepositRequest_.Remitter, paymentTokenId: String, depositAmount: CashAmount, providerId: Int32, depositTypeId: Int32) -> Single<DepositTransaction> {
        let request = DepositOnlineAccountsRequest(paymentTokenID: paymentTokenId, requestAmount: String(depositAmount.amount), remitter: remitter.name, channel: MOBILE_CHANNEL, remitterAccountNumber: remitter.accountNumber, remitterBankName: "", depositType: depositTypeId, providerId: providerId)
        return bankApi.depositOnline(depositRequest: request).map { (response) -> DepositTransaction in
            guard let data = response.data else {
                return DepositTransaction(id: "", provider: "", transactionId: "", bankId: "")
            }
            
            let transactionData = DepositTransaction(id: data.displayID, provider: data.providerAccountID, transactionId: data.depositTransactionID, bankId: String(data.bankID ?? 0))
            return transactionData
        }
    }
    
    func getDepositMethods(depositType: Int32) -> Single<[PaymentGateway]> {
        let depositMethod = bankApi.getDepositMethods(depositType: depositType).map { (response) -> [DepositMethodData] in
            return response.data ?? []
        }.map {
            $0.map { (m) -> PaymentGateway in
                PaymentGateway(id: m.depositMethodID, limitation: AmountRange(min: CashAmount(amount: m.depositLimitMinimum), max: CashAmount(amount: m.depositLimitMaximum)), paymentToken: m.paymentTokenID, isFavorite: m.isFavorite, provider: PaymentProvider.convert(m.providerId), supportBank: [], displayName: m.displayName, displayType: PaymentGateway.DisplayType.direct)
            }
        }
        
        return depositMethod
    }
    
    func getDepositRecordDetail(transactionId: String) -> Single<DepositDetail> {
        return bankApi.getDepositRecordDetail(displayId: transactionId).flatMap {
            self.createDepositRecordDetail(detail: $0.data!)
        }
    }
    
    func bindingImageWithDepositRecord(displayId: String, transactionId: Int32, portalImages: [PortalImage]) -> Completable {
        let imageBindingData = UploadImagesData(ticketStatus: transactionId, images: portalImages.map { Image(imageID: $0.imageId, fileName: $0.fileName) })
        
        return bankApi.bindingImageWithDepositRecord(displayId: displayId, uploadImagesData: imageBindingData)
    }
    
    func getDepositRecords(page: String, dateBegin: Date, dateEnd: Date, status: [TransactionStatus]) -> Single<[DepositRecord]> {
        var statusDic: [String: Int32] = [:]
        status.enumerated().forEach { statusDic["ticketStatuses[\($0.0)]"] = TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus: $0.1)}
        return bankApi.getDepositRecords(page: page, deteBegin: dateBegin.toDateStartTimeString(with: "-"), dateEnd: dateEnd.toDateStartTimeString(with: "-"), status: statusDic).map { (response) -> [DepositRecord] in
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
    
    func requestCryptoDeposit() -> Single<String> {
        return cpsApi.createCryptoDeposit().map { $0.data?.url ?? "" }
    }
    
    func requestCryptoDetailUpdate(displayId: String) -> Single<String> {
        return bankApi.requestCryptoDetailUpdate(displayId: displayId).map { (response) -> String in
            guard let data = response.data else { return "" }
            return data.url
        }
    }
    
    fileprivate func createDepositRecordDetail(detail: DepositRecordDetailData) -> Single<DepositDetail> {
        return getStatusChangeHistories(statusChangeHistories: detail.statusChangeHistories).map { (tHistories) -> DepositDetail in
            return detail.toDepositDetail(statusChangeHistories: tHistories)
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
                             transactionTransactionType: TransactionType.Companion.init().convertTransactionType(transactionType_: r.ticketType),
                             transactionStatus: TransactionStatus.Companion.init().convertTransactionStatus(ticketStatus_: r.status),
                             actualAmount: CashAmount(amount: r.actualAmount),
                             createdDate: createOffsetDateTime,
                             isFee: r.isFee, isPendingHold: r.isPendingHold,
                             requestAmount: CashAmount(amount: r.requestAmount),
                             updatedDate: updateOffsetDateTime,
                             groupDay: Kotlinx_datetimeLocalDate.init(year: createDate.getYear(), monthNumber: createDate.getMonth(), dayOfMonth: createDate.getDayOfMonth()))
    }
}
