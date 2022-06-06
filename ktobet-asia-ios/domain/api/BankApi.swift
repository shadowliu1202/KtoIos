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

    func getBanks() -> Single<ResponseData<[SimpleBank]>> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/init/bank",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[SimpleBank]>.self)
    }

    func bindingImageWithWithdrawalRecord(displayId: String, uploadImagesData: UploadImagesData) -> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/withdrawal/images/\(displayId)",
                               method: .put,
                               task: .requestJSONEncodable(uploadImagesData),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
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
        let target = GetAPITarget(service: self.url("api/bank-card"))
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

    func isWithdrawalAccountExist(bankId: Int32, bankName: String, accountNumber: String) -> Single<ResponseData<Bool>> {
        let target = GetAPITarget(service: self.url("api/bank-card/check")).parameters(["accountNumber": accountNumber,
                                                                                        "bankName": bankName,
                                                                                        "bankId": bankId])
        return httpClient.request(target).map(ResponseData<Bool>.self)
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

    func getTurnOver() -> Single<ResponseData<TurnoverData>> {
        let target = GetAPITarget(service: self.url("\(prefixW)/turn-over"))
        return httpClient.request(target).map(ResponseData<TurnoverData>.self)
    }

    func requestCryptoDetailUpdate(displayId: String) -> Single<ResponseData<CryptoDepositUrl>> {
        let target = GetAPITarget(service: self.url("\(prefixD)/update-online-deposit-crypto")).parameters(["displayId": displayId])
        return httpClient.request(target).map(ResponseData<CryptoDepositUrl>.self)
    }
    
    func getIsAnyTicketApplying() -> Single<NonNullResponseData<Bool>> {
        let target = GetAPITarget(service: self.url("\(prefixW)/is-apply"))
        return httpClient.request(target).map(NonNullResponseData<Bool>.self)
    }
    
    func isCryptoProcessCertified() -> Single<NonNullResponseData<Bool>> {
        let target = GetAPITarget(service: self.url("\(prefixW)/player-certification/crypto"))
        return httpClient.request(target).map(NonNullResponseData<Bool>.self)
    }
    
    // MARK: New
    func getDepositTypesString() -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/player-deposit-type",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func getDepositLogs() -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func getDepositRecordDetail(displayId: String) -> Single<String> {
        let target = GetAPITarget(service: self.url("\(prefixD)/detail")).parameters(["displayId": displayId])
        return httpClient.requestJsonString(target)
    }
    
    func getDepositOfflineBankAccounts() -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/bank",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func getDepositMethods(depositType: Int32) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/player-deposit-method/",
                               method: .get,
                               task: .requestParameters(parameters: ["depositType": depositType], encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func getBanks() -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/init/bank",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func sendOfflineDepositRequest(request: DepositOfflineBankAccountsRequest) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/offline",
                               method: .post,
                               task: .requestJSONEncodable(request),
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
    
    func sendOnlineDepositRequest(request: DepositOnlineAccountsRequest) -> Single<String> {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/online-deposit",
                               method: .post,
                               task: .requestJSONEncodable(request),
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }

    func bindingImageWithDepositRecord(displayId: String, uploadImagesData: UploadImagesData) -> Completable {
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/images/\(displayId)",
                               method: .put,
                               task: .requestJSONEncodable(uploadImagesData),
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func requestCryptoDetailUpdate(displayId: String) -> Single<String> {
        let target = GetAPITarget(service: self.url("\(prefixD)/update-online-deposit-crypto")).parameters(["displayId": displayId])
        return httpClient.requestJsonString(target)
    }
    
    func getDepositRecords(page: Int32, deteBegin: String, dateEnd: String, status: [String: String]) -> Single<String> {
        var parameters =  ["dateRange.begin" : deteBegin, "dateRange.end": dateEnd]
        status.forEach { parameters[$0.key] = $0.value }
        let target = APITarget(baseUrl: httpClient.baseUrl,
                               path: "api/deposit/logs/\(page)",
                               method: .get,
                               task: .requestParameters(parameters: parameters, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.requestJsonString(target)
    }
}
