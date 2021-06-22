import Foundation
import RxSwift
import SharedBu
import Moya

class BankApi: ApiService {
    let prefixW = "api/withdrawal"
    let prefixD = "api/deposit"
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
    
    func getDepositTypes() -> Single<ResponseData<[DepositTypeData]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/player-deposit-type",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[DepositTypeData]>.self)
    }
    
    func getDepositRecords() -> Single<ResponseData<[DepositRecordData]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[DepositRecordData]>.self)
    }
    
    func getDepositOfflineBankAccounts() -> Single<ResponseData<DepositOfflineBankAccountsData>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/bank",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<DepositOfflineBankAccountsData>.self)
    }
    
    func getBanks() -> Single<ResponseData<[SimpleBank]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/init/bank",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[SimpleBank]>.self)
    }
    
    func depositOffline(depositRequest: DepositOfflineBankAccountsRequest) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/offline",
                               method: .post,
                               task: .requestJSONEncodable(depositRequest),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func depositOnline(depositRequest: DepositOnlineAccountsRequest) -> Single<ResponseData<DepositTransactionData>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/online-player",
                               method: .post,
                               task: .requestJSONEncodable(depositRequest),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<DepositTransactionData>.self)
    }
    
    func getDepositMethods(depositType: Int32) -> Single<ResponseData<[DepositMethodData]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/player-deposit-method/",
                               method: .get,
                               task: .requestParameters(parameters: ["depositType": depositType], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[DepositMethodData]>.self)
    }
    
    func getDepositRecordDetail(displayId: String, ticketType: Int32) -> Single<ResponseData<DepositRecordDetailData>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/detail/",
                               method: .get,
                               task: .requestParameters(parameters: ["displayId": displayId,
                                                                     "ticketType": ticketType], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<DepositRecordDetailData>.self)
    }
    
    func bindingImageWithDepositRecord(displayId: String, uploadImagesData: UploadImagesData) -> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/images/\(displayId)",
                               method: .put,
                               task: .requestJSONEncodable(uploadImagesData),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func bindingImageWithWithdrawalRecord(displayId: String, uploadImagesData: UploadImagesData) -> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/images/\(displayId)",
                               method: .put,
                               task: .requestJSONEncodable(uploadImagesData),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func getDepositRecords(page: String, deteBegin: String, dateEnd: String, status: [String: Int32]) ->     Single<ResponseData<[DepositRecordAllData]>> {
        var parameters =  ["dateRange.begin" : deteBegin, "dateRange.end": dateEnd]
        status.forEach { parameters[$0.key] = String($0.value) }
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/logs/\(page)",
                               method: .get,
                               task: .requestParameters(parameters: parameters, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[DepositRecordAllData]>.self)
    }
    
    func getWithdrawalLimitation() -> Single<ResponseData<DailyWithdrawalLimits>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/limit-count",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<DailyWithdrawalLimits>.self)
    }
    
    func getWithdrawalRecords() -> Single<ResponseData<[WithdrawalRecordData]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[WithdrawalRecordData]>.self)
    }
    
    func getWithdrawalRecordDetail(displayId: String, ticketType: Int32) -> Single<ResponseData<WithdrawalRecordDetailData>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/detail/",
                               method: .get,
                               task: .requestParameters(parameters: ["displayId": displayId,
                                                                     "ticketType": ticketType], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<WithdrawalRecordDetailData>.self)
    }
    
    func getWithdrawalRecords(page: String, deteBegin: String, dateEnd: String, status: [String: Int32]) ->     Single<ResponseData<[WithdrawalRecordAllData]>> {
        var parameters =  ["dateRange.begin" : deteBegin, "dateRange.end": dateEnd]
        status.forEach { parameters[$0.key] = String($0.value) }
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/logs/\(page)",
                               method: .get,
                               task: .requestParameters(parameters: parameters, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[WithdrawalRecordAllData]>.self)
    }
    
    func cancelWithdrawal(ticketId: String) -> Completable {
        let request = WithdrawalCancelRequest(ticketId: ticketId)
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/cancel/",
                               method: .put,
                               task: .requestJSONEncodable(request),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func sendWithdrawalRequest(withdrawalRequest: WithdrawalRequest) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/bank-card",
                               method: .post,
                               task: .requestJSONEncodable(withdrawalRequest),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getWithdrawalAccount() -> Single<ResponseData<PayloadPage<WithdrawalAccountBean>>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/bank-card",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<PayloadPage<WithdrawalAccountBean>>.self)
    }
    
    func sendWithdrawalAddAccount(request: WithdrawalAccountAddRequest) -> Single<ResponseData<Nothing>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/bank-card",
                               method: .post,
                               task: .requestJSONEncodable(request),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<Nothing>.self)
    }
    
    func deleteWithdrawalAccount(playerBankCardId: String) -> Single<ResponseData<Nothing>> {
        let target = DeleteAPITarget(service: self.url("api/bank-card/\(playerBankCardId)"))
        return httpClient.request(target).map(ResponseData<Nothing>.self)
    }
    
    func getEachLimit() -> Single<ResponseData<SingleWithdrawalLimitsData>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/each-limit",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<SingleWithdrawalLimitsData>.self)
    }
}
