import Foundation
import Moya
import RxSwift
import RxSwiftExt
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
    apiCustomService.getCustomerServiceStatus().map({ $0.data })
  }

  func checkInServiceChatRoom() -> Single<Token> {
    apiCustomService.checkToken()
  }

  func verifyCurrentChatRoomToken() -> Single<Bool> {
    apiCustomService.verifyChatRoomToken().map { $0.data }.catchAndReturn(false)
  }

  func isPlayerInChat() -> Single<PlayerInChatBean> {
    apiCustomService.getPlayerInChat()
  }

  func queryChatHistory(page: Int, pageSize: Int = 20) -> Single<(TotalCount, [ChatHistory])> {
    apiCustomService
      .getPlayerChatHistory(
        pageIndex: page,
        pageSize: pageSize)
      .map({ [unowned self] in
        guard let data = $0.data else { return (0, []) }
        let histories = try data.payload.map({ try $0.toChatHistory(timeZone: self.localStorageRepo.localeTimeZone()) })
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

class CustomServiceRepositoryImpl: CustomServiceRepository, ImageRepository {
  private var apiCustomService: CustomServiceApi
  private var localStorageRepo: LocalStorageRepository
  private let httpClient: HttpClient
  private var portalChatRoom: PortalChatRoom? {
    didSet {
      if let room = portalChatRoom {
        chatRoomSubject.onNext(room)
      }
      else {
        chatRoomSubject.onNext(CustomServiceRepositoryImpl.PortalChatRoomNoExist)
      }
    }
  }

  private var chatRoomClient: ChatRoomSignalRClient?
  private var chatRoomSubject = BehaviorSubject<PortalChatRoom>(value: CustomServiceRepositoryImpl.PortalChatRoomNoExist)
  lazy var imageApi: ImageApiProtocol = apiCustomService

  init(_ apiCustomService: CustomServiceApi, _ httpClient: HttpClient, _ localStorageRepo: LocalStorageRepository) {
    self.apiCustomService = apiCustomService
    self.httpClient = httpClient
    self.localStorageRepo = localStorageRepo
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
        ChatMessage.Message(
          id: $0.messageId,
          speaker: self.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
          message: self.covertContentFromInProcess(
            message: $0.message,
            speakerType: EnumMapper.convert(speakerType: $0.speakerType)),
          createTimeTick: try $0.createdDate.toLocalDateTime())
      }
    }
  }

  func removeToken() -> Completable {
    apiCustomService.removeToken()
  }

  func createRoom(survey _: Survey, surveyAnswers: SurveyAnswers?) -> Single<PortalChatRoom> {
    var createRoom: Single<NonNullResponseData<String>>
    if surveyAnswers == nil {
      createRoom = apiCustomService.createRoom(Empty())
    }
    else {
      createRoom = apiCustomService.createRoom(convert(surveyAnswers: surveyAnswers!))
    }

    return createRoom.map { $0.data }
      .flatMap(self.connectChatRoom)
  }

  func currentChatRoom() -> Observable<PortalChatRoom> {
    chatRoomSubject.asObservable()
  }

  private func convert(surveyAnswers: SurveyAnswers) -> PreChatAnswerSurveyBean {
    PreChatAnswerSurveyBean(answerSurvey: AnswerSurveyBean(
      questions: surveyAnswers.answers
        .map { convertToQuestion(answer: $0) }))
  }

  private func convert(survey: Survey, surveyAnswers: SurveyAnswers, roomId: RoomId) -> ExitAnswerSurveyBean {
    ExitAnswerSurveyBean(
      questions: surveyAnswers.answers.map { convertToQuestion(answer: $0) },
      roomId: roomId,
      skillId: survey.csSkillId,
      surveyType: survey.surveyType.ordinal)
  }

  private func convertToQuestion(answer: (key: SurveyQuestion_, value: [SurveyQuestion_.SurveyQuestionOption])) -> Question {
    let (question, options) = answer
    return Question(
      questionId: question.questionId,
      questionText: question.description_,
      surveyAnswerOptions: options.map { self.convertToSurveyAnswerOption(bean: $0) })
  }

  private func convertToSurveyAnswerOption(bean: SurveyQuestion_.SurveyQuestionOption) -> SurveyAnswerOption {
    SurveyAnswerOption(optionId: bean.optionId.isEmpty ? nil : bean.optionId, optionText: bean.values)
  }

  static let PortalChatRoomNoExist = PortalChatRoom.companion.notExist()

  private func connectChatRoom(token: Token) -> Single<PortalChatRoom> {
    Single.create { emitter in
      if self.chatRoomClient?.token != token {
        self.chatRoomClient?.disconnect()
        self.chatRoomClient = ChatRoomSignalRClient(
          token: token,
          repository: self,
          customerInfraService: self,
          httpClient: self.httpClient)
        self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
      }
      else if self.portalChatRoom == nil {
        self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
      }

      emitter(.success(self.portalChatRoom ?? CustomServiceRepositoryImpl.PortalChatRoomNoExist))

      return Disposables.create()
    }
  }

  func connectChatRoom(_ bean: PlayerInChatBean) -> Single<PortalChatRoom> {
    Single.create { [weak self] single in
      guard let self else {
        single(.failure(NSError(domain: "connect socket failed", code: 401, userInfo: nil)))
        return Disposables.create()
      }

      if self.chatRoomClient?.token != bean.token {
        self.chatRoomClient?.disconnect()
        self.chatRoomClient = ChatRoomSignalRClient(
          token: bean.token,
          skillId: bean.skillId,
          roomId: bean.roomId,
          repository: self,
          customerInfraService: self,
          httpClient: self.httpClient)
        self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
      }
      else if self.portalChatRoom == nil {
        self.portalChatRoom = PortalChatRoom(service: self.chatRoomClient!)
      }

      single(.success(self.portalChatRoom ?? CustomServiceRepositoryImpl.PortalChatRoomNoExist))

      return Disposables.create()
    }
  }

  func closeChatRoom(roomId: String) -> Completable {
    chatRoomSubject.onNext(CustomServiceRepositoryImpl.PortalChatRoomNoExist)
    return apiCustomService.closeChatRoom(roomId: roomId).do(onCompleted: { [weak self] in self?.portalChatRoom = nil })
  }

  func send(_ message: String, roomId: String) -> Completable {
    let messages = Message(quillDeltas: [QuillDelta(attributes: nil, insert: message)])
    let sendBean = SendBean(message: messages, roomId: roomId)
    return apiCustomService.send(request: sendBean).asCompletable()
  }

  func send(_ imageId: String, imageName _: String, roomId: String) -> Completable {
    let messages = Message(quillDeltas: [QuillDelta(attributes: Attributes(image: imageId), insert: "\n")])
    let sendBean = SendBean(message: messages, roomId: roomId)
    return apiCustomService.send(request: sendBean).asCompletable()
  }

  func deleteSelectedHistories(chatHistory: [ChatHistory], isExclude: Bool) -> Completable {
    apiCustomService
      .deleteChatHistory(deleteCsRecords: DeleteCsRecords(roomIds: chatHistory.map({ $0.roomId }), isExclude: isExclude))
  }

  func getChatHistory(roomId: RoomId) -> Single<[ChatMessage]> {
    apiCustomService.getChatHistory(roomId: roomId)
      .map { response in
        let roomHistories = response.data.roomHistories
        return try roomHistories.map { try self.toChatMessage(history: $0) }
      }
  }

  func convertSpeaker(speaker: String, speakerType: Int32) -> PortalChatRoom.Speaker {
    switch EnumMapper.convert(speakerType: speakerType) {
    case .player:
      return PortalChatRoom.SpeakerPlayer(name: speaker)
    case .handler:
      return PortalChatRoom.SpeakerHandler(name: speaker)
    case .system:
      return PortalChatRoom.SpeakerSystem(name: speaker)
    default:
      return PortalChatRoom.SpeakerPlayer(name: speaker)
    }
  }

  private func toChatMessage(history: RoomHistory) throws -> ChatMessage {
    ChatMessage.Message(
      id: history.messageId,
      speaker: convertSpeaker(speaker: history.speaker, speakerType: history.speakerType),
      message: covertContentFromInProcess(
        message: history.message,
        speakerType: EnumMapper.convert(speakerType: history.speakerType)),
      createTimeTick: try history.createdDate.toLocalDateTime())
  }

  func covertContentFromInProcess(message: Message, speakerType _: SpeakerType) -> [ChatMessage.Content] {
    message.quillDeltas.map { it in
      if let image = it.attributes?.image {
        return ChatMessage
          .ContentImage(image: PortalImage.ChatImage(host: httpClient.host.absoluteString, path: image, isInChat: false))
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
  func getSurveyGetChatHistoryQuestion(surveyType: Survey.SurveyType) -> Single<Survey>
  func setOfflineSurveyAnswers(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Completable
  func connectSurveyWithChatRoom(surveyConnectionId: SurveyConnectionId, chatRoomId: RoomId) -> Completable
  func createOfflineSurvey(message: String, email: String) -> Completable
}

extension CustomServiceRepositoryImpl: SurveyInfraService {
  func getSurveyGetChatHistoryQuestion(surveyType: Survey.SurveyType) -> Single<Survey> {
    apiCustomService
      .getSkillSurvey(type: surveyType.ordinal)
      .map { $0.data.toSurvey() }
  }

  private func convertPlatform(_ platform: Survey.Platform) -> Int {
    switch platform {
    case .ios: return 0
    case .android: return 1
    case .web: return 2
    case .wb: return 99
    default: return 2
    }
  }

  func setOfflineSurveyAnswers(roomId: RoomId, survey: Survey, surveyAnswers: SurveyAnswers) -> Completable {
    apiCustomService.answerSurvey(body: convert(survey: survey, surveyAnswers: surveyAnswers, roomId: roomId))
  }

  func connectSurveyWithChatRoom(surveyConnectionId: SurveyConnectionId, chatRoomId: RoomId) -> Completable {
    apiCustomService.connectSurveyWithRoom(connectId: surveyConnectionId, roomId: chatRoomId)
  }

  func createOfflineSurvey(message: String, email: String) -> Completable {
    apiCustomService.createOfflineSurvey(CustomerMessageData(content: message, email: email))
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
