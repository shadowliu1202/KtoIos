//
//  CustomServiceApi.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/18.
//

import Foundation
import RxSwift
import SwiftyJSON
import Moya


class CustomServiceApi: ApiService, ImageApiProtocol {
    let prefix = "onlinechat/api"
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

    var baseUrl: URL {
        return httpClient.host
    }
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func getBelongedSkillId(platform: Int) -> Single<ResponseData<String>> {
        let para = ["platForm": platform]
        let target = APITarget(baseUrl: httpClient.host,
                               path: "onlinechat/api/survey/skill",
                               method: .get,
                               task: .requestParameters(parameters: para, encoding: URLEncoding.default),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func getInProcessInformation(roomId: String) -> Single<ResponseData<[InProcessBean]>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "onlinechat/api/room/in-process",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<[InProcessBean]>.self)
    }
    
    func removeToken() -> Completable {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "onlinechat/api/common/remove-token",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func closeChatRoom(roomId: String) -> Completable {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "onlinechat/api/room/player/close",
                               method: .post,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).asCompletable()
    }
    
    func checkToken() -> Single<String> {
        let target = GetAPITarget(service: self.url("\(prefix)/common/check"))
        return httpClient.request(target).map(NonNullResponseData<String>.self).map({$0.data})
    }
    
    func verifyChatRoomToken() -> Single<NonNullResponseData<Bool>> {
        let target = GetAPITarget(service: self.url("\(prefix)/chat-system/token-validation"))
        return httpClient.request(target).map(NonNullResponseData<Bool>.self)
    }
    
    func getPlayerInChat() -> Single<PlayerInChatBean> {
        let target = GetAPITarget(service: self.url("\(prefix)/room/player/in-chat"))
        return httpClient.request(target).map(NonNullResponseData<PlayerInChatBean>.self).map({$0.data})
    }
    
    func send(request: SendBean) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "onlinechat/api/room/send",
                               method: .post,
                               task: .requestJSONEncodable(request),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }
    
    func uploadImage(query: [String: Any], imageData: [MultipartFormData]) -> Single<ResponseData<String>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "onlinechat/api/image/upload",
                               method: .post,
                               task: .uploadCompositeMultipart(imageData, urlParameters: query),
                               header: httpClient.headers)
        return httpClient.request(target).map(ResponseData<String>.self)
    }

    /**
     * Step 1: Check CS Status
     */
    func getCustomerServiceStatus() -> Single<NonNullResponseData<Bool>> {
        let target = GetAPITarget(service: self.url("\(prefix)/room/cs-status"))
        return httpClient.request(target).map(NonNullResponseData<Bool>.self)
    }
    
    /**
     * Step 3: createCustomeService survey or Ignore(will Skip Step 5)
     */
    func createSurveyWithAnswer(_ request: CreateSurveyRequest) -> Single<NonNullResponseData<String>> {
        let target = PostAPITarget(service: self.url("\(prefix)/survey/create"), parameters: request)
        return httpClient.request(target).map(NonNullResponseData<String>.self)
    }
    /**
     * Step 4: create customer ChatRoom token for conversation
     */
    func createTokenForUserConversation(skillId: SkillId) -> Single<NonNullResponseData<Token>> {
        let target = GetAPITarget(service: self.url("api/pchat/create-token")).parameters(["skillId" : skillId])
        return httpClient.request(target).map(NonNullResponseData<Token>.self)
    }
    /**
     * Step 5: Connect Room and Survey if have step 3
     */
    func connectSurveyWithRoom(connectId: String, roomId: String) -> Completable {
        let target = PostAPITarget(service: self.url("\(prefix)/survey/set-survey-room/\(connectId)/\(roomId)"),parameters: Empty())
        return httpClient.request(target).asCompletable()
    }
    
    func createOfflineSurvey(_ request: CustomerMessageData) -> Completable {
        let target = PostAPITarget(service: self.url("\(prefix)/survey/create-offline"), parameters: request)
        return httpClient.request(target).asCompletable()
    }
    
    func deleteChatHistory(deleteCsRecords: DeleteCsRecords) -> Completable {
        let target = PutAPITarget(service: self.url("api/room/records"), parameters: deleteCsRecords)
        return httpClient.request(target).asCompletable()
    }
    
    func getChatHistory(roomId: RoomId) -> Single<NonNullResponseData<ChatHistoryBean>> {
        let target = APITarget(baseUrl: httpClient.host,
                               path: "api/room/record/\(roomId)",
                               method: .get,
                               task: .requestPlain,
                               header: httpClient.headers)
        return httpClient.request(target).map(NonNullResponseData<ChatHistoryBean>.self)
    }
    
    func getPlayerChatHistory(pageIndex: Int = 1, pageSize: Int = 20) -> Single<ResponseData<ChatHistories>> {
        let target = GetAPITarget(service: self.url("api/room")).parameters(["page" : pageIndex, "pageSize" : pageSize])
        return httpClient.request(target).map(ResponseData<ChatHistories>.self)
    }
    
    func createRoom(_ bean: Encodable) -> Single<NonNullResponseData<String>> {
        let target = PostAPITarget(service: self.url("\(prefix)/room"), parameters: bean)
        return httpClient.request(target).map(NonNullResponseData<String>.self)
    }
    
    func getSkillSurvey(type: Int32, skillId: String?) -> Single<NonNullResponseData<SurveyBean>> {
        var parameters: [String: Any] = [:]
        parameters["type"] = type
        if let skillId = skillId {
            parameters["skillId"] = skillId
        }
        
        let target = GetAPITarget(service: self.url("\(prefix)/survey/skill-survey"))
            .parameters(parameters)
        return httpClient.request(target).map(NonNullResponseData<SurveyBean>.self)
    }
    
    func answerSurvey(body: ExitAnswerSurveyBean) -> Completable {
        let target = PostAPITarget(service: self.url("\(prefix)/survey/answer"), parameters: body)
        return httpClient.request(target).asCompletable()
    }
}
