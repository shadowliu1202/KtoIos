import Foundation
import sharedbu

class CashAdapter: CashProtocol {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func getBalanceDetailTransaction(id: String) -> SingleWrapper<ResponseItem<TransactionLogDetailBean>> {
        httpClient.request(
            path: "api/cash/balance-detail/transaction/\(id)",
            method: .get
        )
        .asReaktiveResponseItem(serial: TransactionLogDetailBean.companion.serializer())
    }

    func getBonus(id: String) -> SingleWrapper<ResponseItem<BalanceLogBonusRemarkBean>> {
        httpClient.request(path: "api/bonus/\(id)", method: .get)
            .asReaktiveResponseItem(serial: BalanceLogBonusRemarkBean.companion.serializer())
    }

    func getCash(
        begin: String,
        end: String,
        balanceLogFilterType: Int32,
        page: Int32,
        isDesc: Bool
    )
        -> SingleWrapper<ResponsePayload<CashLogsBean>>
    {
        httpClient.request(
            path: "api/cash",
            method: .get,
            task: .urlParameters([
                "createdDateRange.begin": begin,
                "createdDateRange.end": end,
                "BalanceLogFilterType": balanceLogFilterType,
                "page": page,
                "isDesc": isDesc,
            ])
        )
        .asReaktiveResponsePayload(serial: CashLogsBean.companion.serializer())
    }

    func getIncomeOutcomeAmount(
        begin: String,
        end: String,
        balanceLogFilterType: Int32
    )
        -> SingleWrapper<ResponseItem<IncomeOutcomeBean>>
    {
        httpClient.request(
            path: "api/cash/income-outcome-amount",
            method: .get,
            task: .urlParameters([
                "createdDateRange.begin": begin,
                "createdDateRange.end": end,
                "BalanceLogFilterType": balanceLogFilterType,
            ])
        )
        .asReaktiveResponseItem(serial: IncomeOutcomeBean.companion.serializer())
    }

    func getProductDetailRemark(id: String) -> SingleWrapper<ResponseItem<BalanceLogDetailRemarkBean>> {
        httpClient.request(
            path: "api/cash/product/remark-detail/",
            method: .get,
            task: .urlParameters(["externalId": id])
        )
        .asReaktiveResponseItem(serial: BalanceLogDetailRemarkBean.companion.serializer())
    }

    func getSbkWagerDetail(wagerId: String, offset: Int32) -> SingleWrapper<ResponseItem<NSString>> {
        httpClient.request(
            path: "api/cash/product-sbk/wager-detail",
            method: .get,
            task: .urlParameters([
                "wagerId": wagerId,
                "offset": "\(offset)",
            ])
        )
        .asReaktiveResponseItem()
    }

    func getTransactionSummary(
        begin: String,
        end: String,
        balanceLogFilterType: Int32
    )
        -> SingleWrapper<ResponseItem<CashTransactionSummaryBean>>
    {
        httpClient.request(
            path: "api/cash/transaction-summary",
            method: .get,
            task: .urlParameters(
                [
                    "createdDateRange.begin": begin,
                    "createdDateRange.end": end,
                    "balanceLogFilterType": balanceLogFilterType,
                ])
        )
        .asReaktiveResponseItem(serial: CashTransactionSummaryBean.companion.serializer())
    }
}
