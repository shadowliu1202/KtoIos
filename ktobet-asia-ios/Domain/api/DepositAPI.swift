import Foundation
import RxSwift
import sharedbu

class DepositAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getCryptoCurrency() -> SingleWrapper<ResponseItem<CryptoCurrencyBean>> {
        httpClient.request(path: "api/deposit/crypto-currency", method: .get)
            .asReaktiveResponseItem(serial: sharedbu.CryptoCurrencyBean.companion.serializer())
    }

    func getExchangeFeeSetting(cryptoMarket: Int32) -> SingleWrapper<ResponseItem<FeeSettingBean>> {
        httpClient.request(path: "api/deposit/crypto-exchange/\(cryptoMarket)/fee-setting", method: .get)
            .asReaktiveResponseItem(serial: FeeSettingBean.companion.serializer())
    }

    func getDepositRecordDetail(id: String) -> SingleWrapper<ResponseItem<DepositDetailBean>> {
        httpClient.request(
            path: "api/deposit/detail",
            method: .get,
            task: .urlParameters(["displayId": id])
        )
        .asReaktiveResponseItem(serial: DepositDetailBean.companion.serializer())
    }

    //TODO : not correct usage
    func getDepositLogs() -> ObservableWrapper<ResponseList<DepositLogBean>> {
        httpClient.request(path: "api/deposit", method: .get)
            .asObservable()
            .asReaktiveResponseList(serial: DepositLogBean.companion.serializer())
    }

    func getDepositRecords(
        page: Int32 = 1,
        begin: String,
        end: String,
        status: [String: String]
    ) -> SingleWrapper<ResponseList<DepositLogsBean>> {
        var parameters = status
        parameters["dateRange.begin"] = begin
        parameters["dateRange.end"] = end

        return httpClient.request(
            path: "api/deposit/logs/\(page)",
            method: .get,
            task: .urlParameters(parameters)
        )
        .asReaktiveResponseList(serial: DepositLogsBean.companion.serializer())
    }

    func getDepositMethods(depositType: Int32) -> SingleWrapper<ResponseList<DepositMethodBean>> {
        httpClient.request(
            path: "api/deposit/player-deposit-method/",
            method: .get,
            task: .urlParameters(["depositType": depositType])
        )
        .asReaktiveResponseList(serial: DepositMethodBean.companion.serializer())
    }

    func getDepositOfflineBankAccounts() -> SingleWrapper<ResponseItem<DepositOfflineBankAccountsBean>> {
        httpClient.request(
            path: "api/deposit/bank",
            method: .get
        )
        .asReaktiveResponseItem(serial: DepositOfflineBankAccountsBean.companion.serializer())
    }

    func getDepositTypesString() -> SingleWrapper<ResponseList<DepositTypeBean>> {
        httpClient.request(
            path: "api/deposit/player-deposit-type",
            method: .get
        )
        .asReaktiveResponseList(serial: DepositTypeBean.companion.serializer())
    }

    func getUpdateOnlineDepositCrypto(displayId: String) -> SingleWrapper<ResponseItem<DepositUrlBean>> {
        httpClient.request(
            path: "api/deposit/update-online-deposit-crypto",
            method: .get,
            task: .urlParameters(["displayId": displayId])
        )
        .asReaktiveResponseItem(serial: DepositUrlBean.companion.serializer())
    }

    func onlineDepositCrypto(bean: CryptoDepositRequestBean) -> SingleWrapper<ResponseItem<CryptoDepositResponseBean>> {
        let codable = CryptoDepositRequestBeanCodable(cryptoCurrency: bean.cryptoCurrency)

        return httpClient.request(
            path: "api/deposit/online-deposit-crypto",
            method: .post,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveResponseItem(serial: CryptoDepositResponseBean.companion.serializer())
    }

    func bindingImageWithDepositRecord(id: String, bean: ImageMappingRequestBean) -> sharedbu.Completable {
        let codable = WithdrawalImagesCodable(
            ticketStatus: bean.ticketStatus,
            images: bean.images
                .map { imageBean in
                    ImageBeanCodable(
                        imageID: imageBean.imageId,
                        fileName: imageBean.fileName
                    )
                }
        )
        return httpClient.request(
            path: "api/deposit/images/\(id)",
            method: .put,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveCompletable()
    }

    func sendOfflineDepositRequest(request: DepositOfflineRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
        let codable = DepositOfflineRequestBeanCodable(
            paymentTokenID: request.paymentTokenId,
            requestAmount: request.requestAmount,
            remitterAccountNumber: request.remitterAccountNumber,
            remitter: request.remitter,
            remitterBankName: request.remitterBankName,
            channel: request.channel,
            depositType: request.depositType
        )

        return httpClient.request(
            path: "api/deposit/offline",
            method: .post,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveResponseItem()
    }

    func sendOnlineDepositRequest(request: OnlineDepositRequestBean) -> SingleWrapper<ResponseItem<OnlineDepositResponseBean>> {
        let codable = OnlineDepositRequestBeanCodable(
            paymentTokenID: request.paymentTokenId,
            requestAmount: request.requestAmount,
            remitter: request.remitter,
            channel: request.channel,
            remitterAccountNumber: request.remitterAccountNumber,
            remitterBankName: request.remitterBankName,
            depositType: request.depositType,
            providerId: request.providerId,
            bankCode: request.bankCode
        )

        return httpClient.request(
            path: "api/deposit/online-deposit",
            method: .post,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveResponseItem(serial: OnlineDepositResponseBean.companion.serializer())
    }
}
