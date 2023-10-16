import Foundation
import sharedbu

class DepositAdapter: DepositProtocol {
  private let depositAPI: DepositAPI

  init(_ depositAPI: DepositAPI) {
    self.depositAPI = depositAPI
  }

  func getCryptoCurrency() -> SingleWrapper<ResponseItem<CryptoCurrencyBean>> {
    depositAPI
      .getCryptoCurrency()
      .asReaktiveResponseItem(serial: sharedbu.CryptoCurrencyBean.companion.serializer())
  }

  func getCryptoExchangeFeeSetting(cryptoExchange: Int32) -> SingleWrapper<ResponseItem<FeeSettingBean>> {
    depositAPI
      .getExchangeFeeSetting(cryptoMarket: cryptoExchange)
      .asReaktiveResponseItem(serial: FeeSettingBean.companion.serializer())
  }

  func getDepositDetail(displayId: String) -> SingleWrapper<ResponseItem<DepositDetailBean>> {
    depositAPI
      .getDepositRecordDetail(id: displayId)
      .asReaktiveResponseItem(serial: DepositDetailBean.companion.serializer())
  }

  func getDepositLogs() -> ObservableWrapper<ResponseList<DepositLogBean>> {
    depositAPI
      .getDepositLogs()
      .asObservable()
      .asReaktiveResponseList(serial: DepositLogBean.companion.serializer())
  }

  func getDepositLogs(
    page: Int32,
    begin: String,
    end: String,
    statusMap: [String: String]) -> SingleWrapper<ResponseList<DepositLogsBean>>
  {
    depositAPI
      .getDepositRecords(
        page: page,
        begin: begin,
        end: end,
        status: statusMap)
      .asReaktiveResponseList(serial: DepositLogsBean.companion.serializer())
  }

  func getDepositMethods(depositTypeId: Int32) -> SingleWrapper<ResponseList<DepositMethodBean>> {
    depositAPI
      .getDepositMethods(depositType: depositTypeId)
      .asReaktiveResponseList(serial: DepositMethodBean.companion.serializer())
  }

  func getDepositOfflineBankAccounts() -> SingleWrapper<ResponseItem<DepositOfflineBankAccountsBean>> {
    depositAPI
      .getDepositOfflineBankAccounts()
      .asReaktiveResponseItem(serial: DepositOfflineBankAccountsBean.companion.serializer())
  }

  func getDepositTypes() -> SingleWrapper<ResponseList<DepositTypeBean>> {
    depositAPI
      .getDepositTypesString()
      .asReaktiveResponseList(serial: DepositTypeBean.companion.serializer())
  }

  func getUpdateOnlineDepositCrypto(displayId: String) -> SingleWrapper<ResponseItem<DepositUrlBean>> {
    depositAPI
      .getUpdateOnlineDepositCrypto(displayId: displayId)
      .asReaktiveResponseItem(serial: DepositUrlBean.companion.serializer())
  }

  func onlineDepositCrypto(request: CryptoDepositRequestBean) -> SingleWrapper<ResponseItem<CryptoDepositResponseBean>> {
    depositAPI
      .onlineDepositCrypto(bean: request)
      .asReaktiveResponseItem(serial: CryptoDepositResponseBean.companion.serializer())
  }

  func putDepositImages(displayId: String, imageMappingRequest: ImageMappingRequestBean) -> sharedbu.Completable {
    depositAPI
      .bindingImageWithDepositRecord(id: displayId, bean: imageMappingRequest)
      .asReaktiveCompletable()
  }

  func sendOfflineDepositRequest(request: DepositOfflineRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
    depositAPI
      .sendOfflineDepositRequest(request: request)
      .asReaktiveResponseItem()
  }

  func sendOnlineDepositRequest(request: OnlineDepositRequestBean) -> SingleWrapper<ResponseItem<OnlineDepositResponseBean>> {
    depositAPI
      .sendOnlineDepositRequest(request: request)
      .asReaktiveResponseItem(serial: OnlineDepositResponseBean.companion.serializer())
  }
}
