//
//  CustomServiceRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/12.
//

import Foundation
import RxSwift
import RxSwiftExt
import Moya
import SharedBu

typealias SkillId = String
typealias Token = String
typealias SurveyConnectionId = String
typealias RoomId = String
typealias ConnectId = String
typealias TotalCount = Int

protocol CustomerInfraService {
    func checkCustomerServiceStatus() -> Single<Bool>
    func checkInServiceChatRoom() -> Single<Token>
    func verifyCurrentChatRoomToken() -> Single<Bool>
    func queryChatHistory(page: Int, pageSize: Int) -> Single<(TotalCount, [ChatHistory])>
    func uploadImage(imageData: Data) -> Single<UploadImageDetail>
    func isPlayerInChat() -> Single<PlayerInChatBean>
}

extension CustomServiceRepositoryImpl: CustomerInfraService {
    func checkCustomerServiceStatus() -> Single<Bool> {
        apiCustomService.getCustomerServiceStatus().map({$0.data})
    }
    
    func checkInServiceChatRoom() -> Single<Token> {
        apiCustomService.checkToken()
    }
    
    func verifyCurrentChatRoomToken() -> Single<Bool> {
        apiCustomService.verifyChatRoomToken().map{ $0.data }.catchErrorJustReturn(false)
    }
    
    func isPlayerInChat() -> Single<PlayerInChatBean> {
        apiCustomService.getPlayerInChat()
    }
    
    func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
        let uuid = UUID().uuidString + ".jpeg"
        let completables = createChunks(imageData: imageData, uuid: uuid)
        return Single.zip(completables).flatMap { (tokens) -> Single<UploadImageDetail> in
            let token = tokens.filter { $0.count != 0 }
            let uploadImageDetail = UploadImageDetail(uriString: uuid, portalImage: PortalImage.Private.init(imageId: token.first!, fileName: uuid, host: uuid), fileName: uuid)
            return Single.just(uploadImageDetail)
        }
    }
    
    private func createChunks(imageData: Data, uuid: String) -> [Single<String>] {
        var chunks: [Data] = []
        var completables: [Single<String>] = []
        let mimiType = "image/jpeg"
        let totalSize = imageData.count
        let dataLen = imageData.count
        let chunkSize = 819200
        let fullChunks = Int(dataLen / chunkSize)
        let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
        for chunkCounter in 0..<totalChunks {
            var chunk:Data
            let chunkBase = chunkCounter * chunkSize
            var diff = chunkSize
            if(chunkCounter == totalChunks - 1) {
                diff = dataLen - chunkBase
            }
            
            chunk = imageData.subdata(in: chunkBase..<(chunkBase + diff))
            chunks.append(chunk)
        }
        
        for (index, chunk) in chunks.enumerated() {
            let chunkImageDetil = ChunkImageDetil(resumableChunkNumber: String(index + 1),
                                                  resumableChunkSize: String(chunkSize),
                                                  resumableCurrentChunkSize: String(chunk.count),
                                                  resumableTotalSize: String(totalSize),
                                                  resumableType: mimiType,
                                                  resumableIdentifier: uuid,
                                                  resumableFilename: uuid,
                                                  resumableRelativePath: uuid,
                                                  resumableTotalChunks: String(chunks.count),
                                                  file: chunk)
            let m1 = MultipartFormData(provider: .data(String(index + 1).data(using: .utf8)!), name: "resumableChunkNumber")
            let m2 = MultipartFormData(provider: .data(String(chunk.count).data(using: .utf8)!), name: "resumableChunkSize")
            let m3 = MultipartFormData(provider: .data(String(chunk.count).data(using: .utf8)!), name: "resumableCurrentChunkSize")
            let m4 = MultipartFormData(provider: .data(String(totalSize).data(using: .utf8)!), name: "resumableTotalSize")
            let m5 = MultipartFormData(provider: .data(mimiType.data(using: .utf8)!), name: "resumableType")
            let m6 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableIdentifier")
            let m7 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableFilename")
            let m8 = MultipartFormData(provider: .data(uuid.data(using: .utf8)!), name: "resumableRelativePath")
            let m9 = MultipartFormData(provider: .data(String(chunks.count).data(using: .utf8)!), name: "resumableTotalChunks")
            let multiPartData = MultipartFormData(provider: .data(chunk), name: "file", fileName: uuid, mimeType: mimiType)
            let query = createQuery(chunkImageDetil: chunkImageDetil)
            completables.append(apiCustomService.uploadImage(query: query, imageData: [m1,m2,m3,m4,m5,m6,m7,m8,m9,multiPartData]).map { $0.data ?? "" })
        }
        
        return completables
    }
    
    private func createQuery(chunkImageDetil: ChunkImageDetil) -> [String: Any] {
        var query: [String: Any] = [:]
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(chunkImageDetil)
            query = try (JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, Any>)!
        } catch {
            print(error)
        }
        
        if let idx = query.index(forKey: "file") {
            query.remove(at: idx)
        }
        
        return query
    }
    
    func queryChatHistory(page: Int, pageSize: Int = 20) -> Single<(TotalCount, [ChatHistory])> {
        apiCustomService.getPlayerChatHistory(pageIndex: page, pageSize: pageSize).map({ [unowned self] in
            guard let data = $0.data else { return (0, []) }
            let histories = try data.payload.map({ try $0.toChatHistory(timeZone: self.playerConfig.localeTimeZone()) })
            return (data.totalCount, histories)
        })
    }
}

protocol CustomServiceRepository {
    func getBelongedSkillId(platform: Int) -> Single<SkillId>
    func getInProcessChatMessageHistory(roomId: String) -> Single<[ChatMessage]>
    func removeToken() -> Completable
    func closeChatRoom(roomId: String) -> Completable
    func send(_ message: String, roomId: String) -> Completable
    func send(_ imageId: String, imageName: String, roomId: String) -> Completable
    func checkCustomerServiceStatus() -> Single<Bool>
    func connectChatRoom(_ bean: PlayerInChatBean) -> Single<PortalChatRoom>
    func convertSpeaker(speaker: String, speakerType: Int32) -> PortalChatRoom.Speaker
    func createRoom(survey: Survey, surveyAnswers: SurveyAnswers?) -> Single<PortalChatRoom>
    func deleteSelectedHistories(chatHistory: [ChatHistory], isExclude: Bool) -> Completable
    func getChatHistory(roomId: RoomId) -> Single<[ChatMessage]>
    func covertContentFromInProcess(message: Message, speakerType: SpeakerType) -> [ChatMessage.Content]
    func currentChatRoom() -> Observable<PortalChatRoom>
}

class CustomServiceRepositoryImpl : CustomServiceRepository {
    private var apiCustomService : CustomServiceApi!
    private var playerConfig: PlayerConfiguration
    private let httpClient: HttpClient
    private var portalChatRoom: PortalChatRoom? = nil {
        didSet {
            if let room = portalChatRoom {
                chatRoomSubject.onNext(room)
            } else {
                chatRoomSubject.onNext(CustomServiceRepositoryImpl.PortalChatRoomNoExist)
            }
        }
    }
    private var chatRoomClient: ChatRoomSignalRClient? = nil
    private var chatRoomSubject = BehaviorSubject<PortalChatRoom>(value: CustomServiceRepositoryImpl.PortalChatRoomNoExist)
    
    init(_ apiCustomService : CustomServiceApi, _ httpClient: HttpClient, _ playerConfig: PlayerConfiguration) {
        self.apiCustomService = apiCustomService
        self.httpClient = httpClient
        self.playerConfig = playerConfig
    }
    
    func getBelongedSkillId(platform: Int) -> Single<String> {
        apiCustomService.getBelongedSkillId(platform: platform).flatMap { response in
            guard let data = response.data else { return Single<String>.error(KTOError.EmptyData) }
            return Single.just(data)
        }
    }
    
    func getInProcessChatMessageHistory(roomId: String) -> Single<[ChatMessage]> {
        apiCustomService.getInProcessInformation(roomId: roomId).map { response in
            guard let data = response.data else { return [] }
            return try data.map {
                ChatMessage.Message(id: $0.messageId,
                                    speaker: self.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
                                    message: self.covertContentFromInProcess(message: $0.message, speakerType: EnumMapper.convert(speakerType: $0.speakerType)),
                                    createTimeTick: try $0.createdDate.toLocalDateTime())
            }
        }
    }
    
    func removeToken() -> Completable {
        apiCustomService.removeToken()
    }
    
    func createRoom(survey: Survey, surveyAnswers: SurveyAnswers?) -> Single<PortalChatRoom> {
        var createRoom: Single<NonNullResponseData<String>>
        if surveyAnswers == nil {
            createRoom = apiCustomService.createRoom(Empty())
        } else {
            createRoom = apiCustomService.createRoom(convert(surveyAnswers: surveyAnswers!))
        }
        
        return createRoom.map{ $0.data }
        .flatMap(self.connectChatRoom)
    }
    
    func currentChatRoom() -> Observable<PortalChatRoom> {
        chatRoomSubject.asObservable()
    }
    
    private func convert(surveyAnswers: SurveyAnswers) -> PreChatAnswerSurveyBean {
        PreChatAnswerSurveyBean(answerSurvey: AnswerSurveyBean(questions: surveyAnswers.answers.map { convertToQuestion(answer: $0) }))
    }
    
    private func convert(survey: Survey, surveyAnswers: SurveyAnswers, roomId: RoomId) -> ExitAnswerSurveyBean {
        ExitAnswerSurveyBean(questions: surveyAnswers.answers.map { convertToQuestion(answer: $0) },
                             roomId: roomId,
                             skillId: survey.csSkillId,
                             surveyType: survey.surveyType.ordinal)
    }
    
    private func convertToQuestion(answer: (key: SurveyQuestion_, value: [SurveyQuestion_.SurveyQuestionOption])) -> Question {
        let (question, options) = answer
        return Question(questionId: question.questionId,
                        questionText: question.description_,
                        surveyAnswerOptions: options.map { self.convertToSurveyAnswerOption(bean: $0) })
    }
    
    private func convertToSurveyAnswerOption(bean: SurveyQuestion_.SurveyQuestionOption) -> SurveyAnswerOption {
        SurveyAnswerOption(optionId: bean.optionId.isEmpty ? nil : bean.optionId, optionText: bean.values)
    }
    
    static let PortalChatRoomNoExist = PortalChatRoom.companion.notExist()

    private func connectChatRoom(token: Token) -> Single<PortalChatRoom> {
        Single.create { emitter in
            if (self.chatRoomClient?.token != token) {
                self.chatRoomClient?.disconnect()
                self.chatRoomClient = ChatRoomSignalRClient(token: token, repository: self, customerInfraService: self, httpClient: self.httpClient)
                self.portalChatRoom = PortalChatRoom.init(service: self.chatRoomClient!)
            } else if (self.portalChatRoom == nil) {
                self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
            }
            
            emitter(.success(self.portalChatRoom ?? CustomServiceRepositoryImpl.PortalChatRoomNoExist))
            
            return Disposables.create()
        }
    }
    
    func connectChatRoom(_ bean: PlayerInChatBean) -> Single<PortalChatRoom> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.init(domain: "connect socket failed", code: 401, userInfo: nil)))
                return Disposables.create()
            }
            
            if self.chatRoomClient?.token != bean.token {
                self.chatRoomClient?.disconnect()
                self.chatRoomClient = ChatRoomSignalRClient(token: bean.token, skillId: bean.skillId, roomId: bean.roomId, repository: self, customerInfraService: self, httpClient: self.httpClient)
                self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
            } else if self.portalChatRoom == nil {
                self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
            }
            
            single(.success(self.portalChatRoom ?? CustomServiceRepositoryImpl.PortalChatRoomNoExist))
            
            return Disposables.create()
        }
    }
    
    func closeChatRoom(roomId: String) -> Completable {
        chatRoomSubject.onNext(CustomServiceRepositoryImpl.PortalChatRoomNoExist)
        return apiCustomService.closeChatRoom(roomId: roomId).do(onCompleted: {[weak self] in self?.portalChatRoom = nil })
    }
    
    func send(_ message: String, roomId: String) -> Completable {
        let messages = Message(quillDeltas: [QuillDelta(attributes: nil, insert: message)])
        let sendBean = SendBean(message: messages, roomId: roomId)
        return apiCustomService.send(request: sendBean).asCompletable()
    }
    
    func send(_ imageId: String, imageName: String, roomId: String) -> Completable {
        let messages = Message(quillDeltas: [QuillDelta(attributes: Attributes(image: imageId), insert: "\n")])
        let sendBean = SendBean(message: messages, roomId: roomId)
        return apiCustomService.send(request: sendBean).asCompletable()
    }
    
    func deleteSelectedHistories(chatHistory: [ChatHistory], isExclude: Bool) -> Completable {
        return apiCustomService.deleteChatHistory(deleteCsRecords: DeleteCsRecords(roomIds: chatHistory.map({$0.roomId}), isExclude: isExclude))
    }
    
    func getChatHistory(roomId: RoomId) -> Single<[ChatMessage]> {
        apiCustomService.getChatHistory(roomId: roomId)
            .map { response in
                let roomHistories = response.data.roomHistories
                return try roomHistories.map{ try self.toChatMessage(history: $0) }
            }
    }
    
    func convertSpeaker(speaker: String, speakerType: Int32) -> PortalChatRoom.Speaker {
        switch EnumMapper.convert(speakerType: speakerType) {
        case .player:
            return PortalChatRoom.SpeakerPlayer.init(name: speaker)
        case .handler:
            return PortalChatRoom.SpeakerHandler.init(name: speaker)
        case .system:
            return PortalChatRoom.SpeakerSystem.init(name: speaker)
        default:
            return PortalChatRoom.Speaker.init()
        }
    }
    
    private func toChatMessage(history: RoomHistory) throws -> ChatMessage {
        ChatMessage.Message(id: history.messageId,
                            speaker: convertSpeaker(speaker: history.speaker, speakerType: history.speakerType),
                            message: covertContentFromInProcess(message: history.message, speakerType: EnumMapper.convert(speakerType: history.speakerType)),
                            createTimeTick: try history.createdDate.toLocalDateTime())
    }
    
    func covertContentFromInProcess(message: Message, speakerType: SpeakerType) -> [ChatMessage.Content] {
        message.quillDeltas.map { it in
            if let image = it.attributes?.image {
                return ChatMessage.ContentImage(image: PortalImage.ChatImage(host: httpClient.host.absoluteString, path: image))
            }
            
            if let link = it.attributes?.link {
                return ChatMessage.ContentLink(content: link)
            }
            
            return ChatMessage.ContentText(content: it.insert ?? "", attributes: it.attributes?.convert())
        }
    }
}

struct Argument: Codable {
    let roomID, skillID: String
    
    enum CodingKeys: String, CodingKey {
        case roomID = "roomId"
        case skillID = "skillId"
    }
}


protocol SurveyInfraService {
    func getSurveygetChatHistoryQuestion(surveyType: Survey.SurveyType, skillId: SkillId?) -> Single<Survey>
    func setOfflineSurveyAnswers(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Completable
    func connectSurveyWithChatRoom(surveyConnectionId: SurveyConnectionId, chatRoomId: RoomId) -> Completable
    func createOfflineSurvey(message: String, email: String) -> Completable
}

extension CustomServiceRepositoryImpl: SurveyInfraService {
    func getSurveygetChatHistoryQuestion(surveyType: Survey.SurveyType, skillId: SkillId?) -> Single<Survey> {
        apiCustomService.getSkillSurvey(type: surveyType.ordinal, skillId: skillId).map{ $0.data.toSurvey() }
    }
    
    private func convertPlatform(_ platform: Survey.Platform) -> Int {
        switch platform {
        case .ios:      return 0
        case .android:  return 1
        case .web:      return 2
        case .wb:       return 99
        default:        return 2
        }
    }
    
    func setOfflineSurveyAnswers(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Completable {
        apiCustomService.answerSurvey(body: convert(survey: survey, surveyAnswers: surveyAnswers, roomId: roomId))
    }
    
    func connectSurveyWithChatRoom(surveyConnectionId: SurveyConnectionId, chatRoomId: RoomId) -> Completable {
        return apiCustomService.connectSurveyWithRoom(connectId: surveyConnectionId, roomId: chatRoomId)
    }
    
    func createOfflineSurvey(message: String, email: String) -> Completable {
        return apiCustomService.createOfflineSurvey(CustomerMessageData(content: message, email: email))
    }
}


struct AnswerSurveyBean: Codable {
    let questions: [Question]
}

struct Question: Codable {
    let questionId: String
    let questionText: String
    let surveyAnswerOptions: [SurveyAnswerOption]
}

struct SurveyAnswerOption: Codable {
    let optionId: String?
    let optionText: String
}
