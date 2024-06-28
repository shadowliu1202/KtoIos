import Foundation
import sharedbu

class DepositAdapter: DepositProtocol {
    private let depositAPI: DepositAPI

    init(_ depositAPI: DepositAPI) {
        self.depositAPI = depositAPI
    }

    func getCryptoCurrency() -> SingleWrapper<ResponseItem<CryptoCurrencyBean>> {
        depositAPI.getCryptoCurrency()
    }

    func getCryptoExchangeFeeSetting(cryptoExchange: Int32) -> SingleWrapper<ResponseItem<FeeSettingBean>> {
        depositAPI.getExchangeFeeSetting(cryptoMarket: cryptoExchange)
    }

    func getDepositDetail(displayId: String) -> SingleWrapper<ResponseItem<DepositDetailBean>> {
        depositAPI.getDepositRecordDetail(id: displayId)
    }

    func getDepositLogs() -> ObservableWrapper<ResponseList<DepositLogBean>> {
        depositAPI.getDepositLogs()
    }

    func getDepositLogs(page: Int32, begin: String, end: String, statusMap: [String: String]) -> SingleWrapper<ResponseList<DepositLogsBean>> {
        depositAPI.getDepositRecords(page: page, begin: begin, end: end, status: statusMap)
    }

    func getDepositMethods(depositTypeId: Int32) -> SingleWrapper<ResponseList<DepositMethodBean>> {
        depositAPI.getDepositMethods(depositType: depositTypeId)
    }

    func getDepositOfflineBankAccounts() -> SingleWrapper<ResponseItem<DepositOfflineBankAccountsBean>> {
        depositAPI.getDepositOfflineBankAccounts()
    }

    func getDepositTypes() -> SingleWrapper<ResponseList<DepositTypeBean>> {
        depositAPI.getDepositTypesString()
    }

    func getUpdateOnlineDepositCrypto(displayId: String) -> SingleWrapper<ResponseItem<DepositUrlBean>> {
        depositAPI.getUpdateOnlineDepositCrypto(displayId: displayId)
    }

    func onlineDepositCrypto(request: CryptoDepositRequestBean) -> SingleWrapper<ResponseItem<CryptoDepositResponseBean>> {
        depositAPI.onlineDepositCrypto(bean: request)
    }

    func putDepositImages(displayId: String, imageMappingRequest: ImageMappingRequestBean) -> sharedbu.Completable {
        depositAPI.bindingImageWithDepositRecord(id: displayId, bean: imageMappingRequest)
    }

    func sendOfflineDepositRequest(request: DepositOfflineRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
        depositAPI.sendOfflineDepositRequest(request: request)
    }

    func sendOnlineDepositRequest(request: OnlineDepositRequestBean) -> SingleWrapper<ResponseItem<OnlineDepositResponseBean>> {
        depositAPI.sendOnlineDepositRequest(request: request)
    }
}
