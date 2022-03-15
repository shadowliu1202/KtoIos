import Foundation
import RxSwift
import Moya

class TransactionLogApi: ApiService {
    let prefix = "api/cash"
    private var urlPath: String!
    
    private func url(_ u: String) -> Self {
        self.urlPath = u
        return self
    }
    private var httpClient : HttpClient!
    
    var surfixPath: String {
        return self.urlPath
    }
    
    var headers: [String : String]? {
        return httpClient.headers
    }
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func searchBalanceLogs(begin: String, end: String, balanceLogFilterType: Int, page: Int = 1, isDesc: Bool = true) -> Single<ResponseData<PayloadPage<BalanceDateLogBean>>> {
        let target = GetAPITarget(service: self.url("\(prefix)")).parameters(["createdDateRange.begin": begin,
                                                                              "createdDateRange.end": end,
                                                                              "BalanceLogFilterType": balanceLogFilterType,
                                                                              "page": page,
                                                                              "isDesc": isDesc])
        return httpClient.request(target).map(ResponseData<PayloadPage<BalanceDateLogBean>>.self)
    }
    
    func getIncomeOutcomeAmount(begin: String, end: String, balanceLogFilterType: Int) -> Single<ResponseData<IncomeOutcomeBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/income-outcome-amount"))
            .parameters(["createdDateRange.begin": begin,
                         "createdDateRange.end": end,
                         "BalanceLogFilterType": balanceLogFilterType])
        return httpClient.request(target).map(ResponseData<IncomeOutcomeBean>.self)
    }
    
    func getCashLogSummary(begin: String, end: String, balanceLogFilterType: Int) -> Single<ResponseData<CashLogSummaryBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/transaction-summary"))
            .parameters(["createdDateRange.begin": begin,
                         "createdDateRange.end": end,
                         "BalanceLogFilterType": balanceLogFilterType])
        return httpClient.request(target).map(ResponseData<CashLogSummaryBean>.self)
    }
    
    func getBalanceLogDetail(transactionId: String) -> Single<NonNullResponseData<BalanceLogDetailBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/balance-detail/transaction/\(transactionId)"))
        return httpClient.request(target).map(NonNullResponseData<BalanceLogDetailBean>.self)
    }
    
    func getBalanceLogBonusRemark(externalId: String) -> Single<ResponseData<BalanceLogBonusRemarkBean>> {
        let target = GetAPITarget(service: self.url("api/bonus/\(externalId)"))
        return httpClient.request(target).map(ResponseData<BalanceLogBonusRemarkBean>.self)
    }
    
    func getBalanceLogDetailRemark(externalId: String) -> Single<ResponseData<BalanceLogDetailRemarkBean>> {
        let target = GetAPITarget(service: self.url("\(prefix)/product/remark-detail/")).parameters(["externalId": externalId])
        return httpClient.request(target).map(ResponseData<BalanceLogDetailRemarkBean>.self)
    }
    
    func getBalanceLogCasinoWagerDetail(wagerId: String, offset: Int32) -> Single<ResponseData<String>> {
        let target = GetAPITarget(service: self.url("\(prefix)/product-casino/wager-detail"))
            .parameters(["wagerId": wagerId,
                         "offset": "\(offset)"])
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getBalanceLogSportsBookWagerDetail(wagerId: String, offset: Int32) -> Single<ResponseData<String>> {
        let target = GetAPITarget(service: self.url("\(prefix)/product-sbk/wager-detail"))
            .parameters(["wagerId": wagerId,
                         "offset": "\(offset)"])
        return httpClient.request(target).map(ResponseData<String>.self)
    }
}
