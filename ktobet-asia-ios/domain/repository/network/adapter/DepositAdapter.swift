import Foundation
import SharedBu

class DepositAdapter: DepositProtocol {
    private var bankAPI: BankApi!
    private var cpsAPI: CPSApi!
    
    init(_ bankAPI: BankApi, _ cpsAPI: CPSApi) {
        self.bankAPI = bankAPI
        self.cpsAPI = cpsAPI
    }
    
    func putDepositImages(displayId: String, imageMappingRequest: ImageMappingRequestBean) -> SharedBu.Completable {
        let imgBeans = imageMappingRequest.images.map({ ImageBean(imageID: $0.imageId, fileName: $0.fileName) })
        let dataBean: UploadImagesData = UploadImagesData(ticketStatus: imageMappingRequest.ticketStatus, images: imgBeans)
        return bankAPI.bindingImageWithDepositRecord(displayId: displayId, uploadImagesData: dataBean).asReaktiveCompletable()
    }
    
    func getCryptoCurrency() -> SingleWrapper<ResponseItem<SharedBu.CryptoCurrencyBean>> {
        self.cpsAPI.getCryptoCurrency().asReaktiveResponseItem(serial: SharedBu.CryptoCurrencyBean.companion.serializer())
    }
    
    func getDepositDetail(displayId: String) -> SingleWrapper<ResponseItem<DepositDetailBean>> {
        self.bankAPI.getDepositRecordDetail(displayId: displayId).asReaktiveResponseItem(serial: DepositDetailBean.companion.serializer())
    }
    
    func getDepositLogs() -> ObservableWrapper<ResponseList<DepositLogBean>> {
        self.bankAPI.getDepositLogs().asObservable().asReaktiveResponseList(serial: DepositLogBean.companion.serializer())
    }
    
    func getDepositLogs(page: Int32, begin: String, end: String, statusMap: [String: String]) -> SingleWrapper<ResponseList<DepositLogsBean>> {
        self.bankAPI.getDepositRecords(page: page, deteBegin: begin, dateEnd: end, status: statusMap).asReaktiveResponseList(serial: DepositLogsBean.companion.serializer())
    }
    
    func getDepositMethods(depositTypeId: Int32) -> SingleWrapper<ResponseList<DepositMethodBean>> {
        self.bankAPI.getDepositMethods(depositType: depositTypeId).asReaktiveResponseList(serial: DepositMethodBean.companion.serializer())
    }
    
    func getDepositOfflineBankAccounts() -> SingleWrapper<ResponseItem<DepositOfflineBankAccountsBean>> {
        self.bankAPI.getDepositOfflineBankAccounts().asReaktiveResponseItem(serial: DepositOfflineBankAccountsBean.companion.serializer())
    }
    
    func getDepositTypes() -> SingleWrapper<ResponseList<DepositTypeBean>> {
        self.bankAPI.getDepositTypesString().asReaktiveResponseList(serial: DepositTypeBean.companion.serializer())
    }
    
    func getUpdateOnlineDepositCrypto(displayId: String) -> SingleWrapper<ResponseItem<DepositUrlBean>> {
        self.bankAPI.requestCryptoDetailUpdate(displayId: displayId).asReaktiveResponseItem(serial: DepositUrlBean.companion.serializer())
    }
    
    func onlineDepositCrypto(request: CryptoDepositRequestBean) -> SingleWrapper<ResponseItem<CryptoDepositResponseBean>> {
        cpsAPI.onlineDepositCrypto(cryptoDepositRequest: CryptoDepositRequest(cryptoCurrency: request.cryptoCurrency)).asReaktiveResponseItem(serial: CryptoDepositResponseBean.companion.serializer())
    }
    
    func sendOfflineDepositRequest(request: DepositOfflineRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
        bankAPI.sendOfflineDepositRequest(request: DepositOfflineBankAccountsRequest(
            paymentTokenID: request.paymentTokenId,
            requestAmount: request.requestAmount,
            remitterAccountNumber: request.remitterAccountNumber,
            remitter: request.remitter,
            remitterBankName: request.remitterBankName,
            channel: request.channel,
            depositType: request.depositType)).asReaktiveResponseItem()
    }
    
    func sendOnlineDepositRequest(request: OnlineDepositRequestBean) -> SingleWrapper<ResponseItem<OnlineDepositResponseBean>> {
        bankAPI.sendOnlineDepositRequest(request: DepositOnlineAccountsRequest(
            paymentTokenID: request.paymentTokenId,
            requestAmount: request.requestAmount,
            remitter: request.remitter,
            channel: request.channel,
            remitterAccountNumber: request.remitterAccountNumber,
            remitterBankName: request.remitterBankName,
            depositType: request.depositType,
            providerId: request.providerId,
            bankCode: request.bankCode)).asReaktiveResponseItem(serial: OnlineDepositResponseBean.companion.serializer())
    }
}
