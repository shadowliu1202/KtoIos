//
//  CustomServiceRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/12.
//

import Foundation
import RxSwift
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
    func isInChat() -> Single<Bool>
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
    
    func isInChat() -> Single<Bool> {
        apiCustomService.getInChat()
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
        return apiCustomService.getPlayerChatHistory(pageIndex: page, pageSize: pageSize).map({
            guard let data = $0.data else { return (0, []) }
            let histories = data.payload.map({ $0.toChatHistory() })
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
    func connectChatRoom(_ token: String) -> Single<PortalChatRoom>
    func convertSpeaker(speaker: String, speakerType: Int32) -> PortalChatRoom.Speaker
    func covertContentFromInProcess(messageType: Int32, html: String, text: String, speakerType: SpeakerType, fileId: String?) -> ChatMessage.Content
    func createCustomerChatRoomToken(skillId: SkillId) -> Single<Token>
    func deleteSelectedHistories(chatHistory: [ChatHistory], isExclude: Bool) -> Completable
    func getChatHistory(roomId: RoomId) -> Single<[ChatMessage]>
}

class CustomServiceRepositoryImpl : CustomServiceRepository {
    private var apiCustomService : CustomServiceApi!
    private var portalChatRoom: PortalChatRoom? = nil
    private var chatRoomClient: ChatRoomSignalRClient? = nil
    
    init(_ apiCustomService : CustomServiceApi) {
        self.apiCustomService = apiCustomService
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
            return data.map {
                ChatMessage.Message.init(id: $0.messageID,
                                         speaker: self.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
                                         message: self.covertContentFromInProcess(messageType: $0.messageType,
                                                                                  html: $0.html,
                                                                                  text: $0.text,
                                                                                  speakerType: EnumMapper.convert(speakerType: $0.speakerType),
                                                                                  fileId: $0.fileID),
                                         createTimeTick: $0.createDate.toLocalDateTime())
            }
        }
    }
    
    func removeToken() -> Completable {
        apiCustomService.removeToken()
    }
    
    func createCustomerChatRoomToken(skillId: SkillId) -> Single<Token> {
        return apiCustomService.createTokenForUserConversation(skillId: skillId)
            .catchError({ (error) in
                let exception = ExceptionFactory.create(error)
                switch exception {
                case is ChatCheckGuestFail:
                    return Single.error(ChatCheckGuestIPFail())
                default:
                    return Single.error(error)
                }
            })
            .map({$0.data})
    }
    
    func connectChatRoom(_ token: String) -> Single<PortalChatRoom> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(NSError.init(domain: "connect socket failed", code: 401, userInfo: nil)))
                return Disposables.create()
            }
            
            if self.chatRoomClient?.token != token {
                self.chatRoomClient?.disconnect()
                self.chatRoomClient = ChatRoomSignalRClient(token: token, repository: self)
                self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
            } else if self.portalChatRoom == nil {
                self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
            }
            
            single(.success(self.portalChatRoom ?? PortalChatRoom.companion.notExist()))
            
            return Disposables.create()
        }
    }
    
    func closeChatRoom(roomId: String) -> Completable {
        apiCustomService.closeChatRoom(roomId: roomId)
    }
    
    func send(_ message: String, roomId: String) -> Completable {
        let sendMessageRequest = SendMessageRequest(html: message, roomId: roomId, text: message, messageType: SharedBu.MessageType.text.ordinal)
        return apiCustomService.send(request: sendMessageRequest)
    }
    
    func send(_ imageId: String, imageName: String, roomId: String) -> Completable {
        let sendMessageRequest = SendMessageRequest(html: "<img src=\"\(imageId)\" alt=\"\">",
                                                    roomId: roomId, text: "", fileId: imageId, fileName: imageName,
                                                    messageType: SharedBu.MessageType.image.ordinal)
        return apiCustomService.send(request: sendMessageRequest)
    }
    
    func deleteSelectedHistories(chatHistory: [ChatHistory], isExclude: Bool) -> Completable {
        return apiCustomService.deleteChatHistory(deleteCsRecords: DeleteCsRecords(roomIds: chatHistory.map({$0.roomId}), isExclude: isExclude))
    }
    
    func getChatHistory(roomId: RoomId) -> Single<[ChatMessage]> {
        return apiCustomService.getChatHistory(roomId: roomId).map({
            guard let data = $0.data else {return []}
            return data.map({ ChatMessage.Message.init(id: $0.messageId,
                                                       speaker: self.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
                                                       message: self.covertContent(messageType: $0.messageType,
                                                                                                html: $0.html,
                                                                                                text: $0.text,
                                                                                                speakerType: EnumMapper.convert(speakerType: $0.speakerType),
                                                                                                fileId: $0.fileId),
                                                       createTimeTick: $0.createTimeTick.toLocalDateTime()) })
            
        })
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
    
    func covertContentFromInProcess(messageType: Int32, html: String, text: String, speakerType: SpeakerType, fileId: String?) -> ChatMessage.Content {
        switch EnumMapper.convert(messageType: messageType) {
        case .text:
            return ChatMessage.ContentText.init(content: text, html: html)
        case .image:
            switch speakerType {
            case .player:
                return ChatMessage.ContentImage.init(image: PortalImage.ChatUser.init(imageId: fileId ?? "", fileName: text, host: HttpClient().host))
            case .handler, .system:
                return ChatMessage.ContentImage.init(image: PortalImage.Public.init(imageId: fileId ?? "", fileName: text, host: HttpClient().host))
            default:
                return ChatMessage.Content.init()
            }
        case .link:
            return ChatMessage.ContentLink.init(content: html)
        default:
            return ChatMessage.Content.init()
        }
    }
    
    func covertContent(messageType: Int32, html: String, text: String, speakerType: SpeakerType, fileId: String?) -> ChatMessage.Content {
        switch EnumMapper.convert(messageType: messageType) {
        case .text:
            return ChatMessage.ContentText.init(content: text, html: html)
        case .image:
            switch speakerType {
            case .player:
                return ChatMessage.ContentImage.init(image: PortalImage.Private.init(imageId: fileId ?? "", fileName: text, host: HttpClient().host))
            case .handler, .system:
                return ChatMessage.ContentImage.init(image: PortalImage.Public.init(imageId: fileId ?? "", fileName: text, host: HttpClient().host))
            default:
                return ChatMessage.Content.init()
            }
        case .link:
            return ChatMessage.ContentLink.init(content: html)
        default:
            return ChatMessage.Content.init()
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
    func getSurveyQuestion(surveyType: Survey.SurveyType, skillId: String?) -> Single<SurveyInformation>
    func setSurveyAnswers(roomId: RoomId?, survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SurveyConnectionId>
    func connectSurveyWithChatRoom(surveyConnectionId: SurveyConnectionId, chatRoomId: RoomId) -> Completable
    func createOfflineSurvey(message: String, email: String) -> Completable
}

extension SurveyInfraService {
    func getSurveyQuestion(surveyType: Survey.SurveyType) -> Single<SurveyInformation> {
        return getSurveyQuestion(surveyType: surveyType, skillId: nil)
    }
    
    func setSurveyAnswers(survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SurveyConnectionId> {
        return setSurveyAnswers(roomId: nil, survey: survey, surveyAnswers: surveyAnswers)
    }
}

extension CustomServiceRepositoryImpl: SurveyInfraService {
    func getSurveyQuestion(surveyType: Survey.SurveyType, skillId: String?) -> Single<SurveyInformation> {
        return apiCustomService.getSkillSurvey(surveyType: surveyType.ordinal, platForm: convertPlatform(Survey.Platform.web)).map({
            SurveyInformation(skillId: $0.data.skillID, survey: $0.data.survey?.toSurvey())
        })
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
    
    func setSurveyAnswers(roomId: RoomId?, survey: Survey, surveyAnswers: SurveyAnswers) -> Single<SurveyConnectionId> {
        let request = CreateSurveyRequest(csSkillID: survey.csSkillId, surveyType: survey.surveyType.ordinal, version: survey.version, surveyAnswers: surveyAnswers.toSurveyAnswerBean(), roomID: roomId)
        return apiCustomService.createSurveyWithAnswer(request).map({$0.data})
    }
    
    func connectSurveyWithChatRoom(surveyConnectionId: SurveyConnectionId, chatRoomId: RoomId) -> Completable {
        return apiCustomService.connectSurveyWithRoom(connectId: surveyConnectionId, roomId: chatRoomId)
    }
    
    func createOfflineSurvey(message: String, email: String) -> Completable {
        return apiCustomService.createOfflineSurvey(CustomerMessageData(content: message, email: email))
    }
}
