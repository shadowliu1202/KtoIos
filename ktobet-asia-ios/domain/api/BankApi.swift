import Foundation
import RxSwift
import share_bu
import Moya

class BankApi {
    private var httpClient : HttpClient!
    
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
}
