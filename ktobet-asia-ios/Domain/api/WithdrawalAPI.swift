import Foundation
import RxSwift
import sharedbu

class WithdrawalAPI {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func deleteWithdrawalAccount(playerBankCardId: String) -> CompletableWrapper {
        httpClient.request(path: "api/bank-card/\(playerBankCardId)", method: .delete)
            .asReaktiveCompletable()
    }

    func isWithdrawalAccountExist(bankId: Int32, bankName: String, accountNumber: String) -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        httpClient.request(
            path: "api/bank-card/check",
            method: .get,
            task: .urlParameters(
                [
                    "accountNumber": accountNumber,
                    "bankName": bankName,
                    "bankId": bankId,
                ])
        )
        .asReaktiveResponseItem()
    }

    func isCryptoProcessCertified() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        httpClient.request(
            path: "api/withdrawal/player-certification/crypto",
            method: .get
        )
        .asReaktiveResponseItem()
    }

    func getBankCard() -> SingleWrapper<ResponseItem<WithdrawalBankCardBean>> {
        httpClient.request(
            path: "api/bank-card",
            method: .get
        )
        .asReaktiveResponseItem(serial: WithdrawalBankCardBean.companion.serializer())
    }

    func getWithdrawalCryptoTransactionSuccessLog() -> SingleWrapper<ResponseItem<CryptoWithdrawalTransactionBean>> {
        httpClient.request(
            path: "api/withdrawal/crypto-transaction-success-log",
            method: .get
        )
        .asReaktiveResponseItem(serial: CryptoWithdrawalTransactionBean.companion.serializer())
    }

    func getWithdrawalDetail(displayId: String) -> SingleWrapper<ResponseItem<WithdrawalLogBeans.LogDetail>> {
        httpClient.request(
            path: "api/withdrawal/detail/",
            method: .get,
            task: .urlParameters(["displayId": displayId])
        )
        .asReaktiveResponseItem(serial: WithdrawalLogBeans.LogDetail.companion.serializer())
    }

    func getWithdrawalEachLimit() -> SingleWrapper<ResponseItem<WithdrawalEachLimitBean>> {
        httpClient.request(
            path: "api/withdrawal/each-limit",
            method: .get
        )
        .asReaktiveResponseItem(serial: WithdrawalEachLimitBean.companion.serializer())
    }

    func getIsAnyTicketApplying() -> SingleWrapper<ResponseItem<KotlinBoolean>> {
        httpClient
            .request(
                path: "api/withdrawal/is-apply",
                method: .get
            )
            .asReaktiveResponseItem()
    }

    func getWithdrawalLimitCount() -> SingleWrapper<ResponseItem<WithdrawalLimitCountBean>> {
        httpClient
            .request(
                path: "api/withdrawal/limit-count",
                method: .get
            )
            .asReaktiveResponseItem(serial: WithdrawalLimitCountBean.companion.serializer())
    }

    func getWithdrawalLogs(
        page: Int = 1,
        dateRangeBegin: String,
        dateRangeEnd: String,
        statusDictionary: [String: String]
    ) -> SingleWrapper<ResponseList<WithdrawalLogBeans>> {
        var parameters = statusDictionary
        parameters["dateRange.begin"] = dateRangeBegin
        parameters["dateRange.end"] = dateRangeEnd

        return httpClient
            .request(
                path: "api/withdrawal/logs/\(page)",
                method: .get,
                task: .urlParameters(parameters)
            )
            .asReaktiveResponseList(serial: WithdrawalLogBeans.companion.serializer())
    }

    func getWithdrawalTurnOverRef() -> SingleWrapper<ResponseItem<WithdrawalTurnOverBean>> {
        httpClient
            .request(
                path: "api/withdrawal/turn-over",
                method: .get
            )
            .asReaktiveResponseItem(serial: WithdrawalTurnOverBean.companion.serializer())
    }

    func getWithdrawals() -> SingleWrapper<ResponseList<WithdrawalLogBeans.LogBean>> {
        httpClient
            .request(
                path: "api/withdrawal",
                method: .get
            )
            .asReaktiveResponseList(serial: WithdrawalLogBeans.LogBean.companion.serializer())
    }

    func postBankCard(bean: BankCardBean) -> CompletableWrapper {
        let codable = BankCardBeanCodable(
            bankID: bean.bankId,
            bankName: bean.bankName,
            branch: bean.branch,
            accountName: bean.accountName,
            accountNumber: bean.accountNumber,
            address: bean.address,
            city: bean.city,
            location: bean.location
        )

        return httpClient
            .request(
                path: "api/bank-card",
                method: .post,
                task: .requestJSONEncodable(codable)
            )
            .asReaktiveCompletable()
    }

    func postWithdrawalToBankCard(bean: WithdrawalBankCardRequestBean) -> SingleWrapper<ResponseItem<NSString>> {
        let codable = WithdrawalBankCardRequestBeanCodable(
            requestAmount: bean.requestAmount.toAccountCurrency().bigAmount.doubleValue(exactRequired: false),
            playerBankCardId: bean.playerBankCardId
        )

        return httpClient
            .request(
                path: "api/withdrawal/bank-card",
                method: .post,
                task: .requestJSONEncodable(codable)
            )
            .asReaktiveResponseItem()
    }

    func createCryptoWithdrawal(request: CryptoWithdrawalRequest) -> SingleWrapper<ResponseItem<NSString>> {
        let codable = CryptoWithdrawalRequestCodable(
            playerCryptoBankCardId: request.playerCryptoBankCardId,
            requestCryptoAmount: request.requestCryptoAmount,
            requestFiatAmount: request.requestFiatAmount,
            cryptoCurrency: request.cryptoCurrency
        )

        return httpClient
            .request(
                path: "api/withdrawal/crypto",
                method: .post,
                task: .requestJSONEncodable(codable)
            )
            .asReaktiveResponseItem()
    }

    func putWithdrawalCancel(bean: WithdrawalCancelBean) -> CompletableWrapper {
        let codable = WithdrawalCancelRequestBeanCodable(ticketId: bean.ticketId)

        return httpClient
            .request(
                path: "api/withdrawal/cancel/",
                method: .put,
                task: .requestJSONEncodable(codable)
            )
            .asReaktiveCompletable()
    }

    func putWithdrawalImages(id: String, bean: WithdrawalImages) -> CompletableWrapper {
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
            path: "api/withdrawal/images/\(id)",
            method: .put,
            task: .requestJSONEncodable(codable)
        )
        .asReaktiveCompletable()
    }
}
