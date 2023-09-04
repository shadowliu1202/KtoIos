import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CustomerServiceViewModel {
  private let chatAppService: IChatAppService
  
  private let chatRoomTempMapper = ChatRoomTempMapper()
  private let surveyTempMapper = SurveyTempMapper()
  
  private var surveyAnswers: SurveyAnswers?
  
  private lazy var observeChatRoom = Observable.from(chatAppService.observeChatRoom()).share(replay: 1)
  
  lazy var chatMaintenanceStatus = currentChatRoom()
    .map(\.isMaintained)
    
  lazy var chatRoomMessage = currentChatRoom()
    .compactMap { [weak chatRoomTempMapper] in chatRoomTempMapper?.convertToReadMessages($0) }

  lazy var chatRoomUnreadMessage = currentChatRoom()
    .compactMap { [weak chatRoomTempMapper] in chatRoomTempMapper?.convertToUnreadMessages($0) }

  lazy var chatRoomStatus = currentChatRoom()
    .compactMap { [weak chatRoomTempMapper] in chatRoomTempMapper?.convertToStatus($0) }
      
  lazy var isPlayerInChat = chatRoomStatus.map { $0 != PortalChatRoom.ConnectStatus.notexist }

  lazy var chatRoomConnection = observeChatRoom.map { $0.status }
  
  lazy var currentQueueNumber = chatRoomConnection.map {
    if let connecting = $0 as? SharedBu.Connection.StatusConnecting {
      return Int(connecting.waitInLine)
    }
    else {
      return 0
    }
  }
  .catchAndReturn(0)
  
  init(_ chatAppService: IChatAppService) {
    self.chatAppService = chatAppService
  }

  func currentChatRoom() -> Observable<CustomerServiceDTO.ChatRoom> {
    observeChatRoom
  }
  
  func createChatRoom() async throws {
    async let status = Observable.from(chatAppService.observeChatRoom())
      .map { $0.status }
      .catchAndReturn(Connection.StatusNotExist())
      .first()
      .value
    
    if try await status == SharedBu.Connection.StatusNotExist() {
      try await create()
    }
  }
  
  private func create() async throws {
    let surveyAnswers = surveyAnswers == nil ? nil : surveyTempMapper.convertToCSSurveyAnswersDTO(surveyAnswers!)

    return try await Completable.from(chatAppService.create(surveyAnswers: surveyAnswers)).value
  }
  
  func connectChatRoom() -> Completable {
    Completable.from(
      chatAppService.create(
        surveyAnswers: surveyAnswers == nil
          ? nil
          : surveyTempMapper.convertToCSSurveyAnswersDTO(surveyAnswers!)))
  }

  func closeChatRoom(forceExit: Bool = false) -> Single<CustomerServiceDTO.ExitChat> {
    Single.from(chatAppService.exit(forceExit: forceExit))
  }

  func send(message: String) -> Completable {
    Completable.from(
      chatAppService
        .send(message: message))
  }

  private func send(message: String, chatRoom: PortalChatRoom) -> Completable {
    Completable.create { completeble in
      chatRoom.send(
        message: message,
        onError: { apiException in
          completeble(.error(apiException))
        })

      return Disposables.create { }
    }
  }
  
  func markAllRead(manual: Bool?, auto: Bool?) async throws {
    try await Completable.from(
      chatAppService.readAllMessage(
        updateToLast: manual == nil ? nil : KotlinBoolean(bool: manual!),
        isAuto: auto == nil ? nil : KotlinBoolean(bool: auto!)))
      .value
  }

  func findCurrentRoomId() -> Single<RoomId> {
    currentChatRoom()
      .map(\.roomId)
      .asSingle()
  }

  private func waitRoomId(portalChatRoom: PortalChatRoom) -> Single<RoomId> {
    Single.create { single in
      portalChatRoom.setRoomIdListener { roomId in
        single(.success(roomId))
      }

      return Disposables.create()
    }
  }

  private func waitSkillId(portalChatRoom: PortalChatRoom) -> Single<RoomId> {
    Single.create { single in
      portalChatRoom.setSkillIdListener { skillId in
        single(.success(skillId))
      }

      return Disposables.create()
    }
  }

  func sendImages(URIs: [String]) -> Completable {
    Completable.from(
      chatAppService
        .send(images: URIs.map { .init(uri: $0, extra: [:]) }))
  }

  func setupSurveyAnswer(answers: SurveyAnswers?) {
    surveyAnswers = answers
  }
}

enum ChatRoomScreen { case Fullscreen, Minimize }
