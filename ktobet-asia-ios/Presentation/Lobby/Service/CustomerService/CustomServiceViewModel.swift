import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CustomerServiceViewModel {
  private let chatAppService: IChatAppService
  
  private let chatRoomTempMapper = ChatRoomTempMapper()
  private let surveyTempMapper = SurveyTempMapper()
  
  private var surveyAnswers: SurveyAnswers?
  
  var screenSizeOption = BehaviorRelay<ChatRoomScreen>(value: .Minimize)

  init(_ chatAppService: IChatAppService) {
    self.chatAppService = chatAppService
  }

  lazy var chatMaintenanceStatus = currentChatRoom()
    .map(\.isMaintained)
    
  lazy var chatRoomMessage = currentChatRoom()
    .map { [unowned self] in chatRoomTempMapper.convertToReadMessages($0) }

  lazy var chatRoomUnreadMessage = currentChatRoom()
    .map { [unowned self] in chatRoomTempMapper.convertToUnreadMessages($0) }

  lazy var preLoadChatRoomStatus = currentChatRoom()
    .map { [unowned self] in chatRoomTempMapper.convertToStatus($0) }

  lazy var observeChatRoom = Observable.from(chatAppService.observeChatRoom()).share(replay: 1)
  
  lazy var chatRoomConnection = observeChatRoom
    .map { result -> SharedBu.Connection.Status in
      guard let chatRoom = result.value else {
        return SharedBu.Connection.StatusNotExist()
      }
      
      return chatRoom.status
    }
  
  lazy var currentQueueNumber = chatRoomConnection.map {
    if let connecting = $0 as? SharedBu.Connection.StatusConnecting {
      return Int(connecting.waitInLine)
    }
    else {
      return 0
    }
  }
  .catchAndReturn(0)
  
  func currentChatRoom() -> Observable<CustomerServiceDTO.ChatRoom> {
    observeChatRoom
      .map { singleResult -> CustomerServiceDTO.ChatRoom in
        if let chatRoomDTO = singleResult.value {
          return chatRoomDTO
        }
        else if let error = singleResult.error {
          if error.exception is ChatRoomNotExist {
            return CustomerServiceDTO.ChatRoom(
              roomId: "",
              readMessage: [],
              unReadMessage: [],
              status: SharedBu.Connection.StatusNotExist(),
              isMaintained: false)
          }
          else {
            throw error.exception.asError()
          }
        }
        
        throw KTOError.EmptyData
      }
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

  func minimize() -> Completable {
    screenSizeOption.accept(.Minimize)
    return Completable.from(
      chatAppService
        .readAllMessage(updateToLast: nil, isAuto: KotlinBoolean(bool: false)))
  }

  func fullscreen() -> Completable {
    screenSizeOption.accept(.Fullscreen)
    return Completable.from(
      chatAppService
        .readAllMessage(updateToLast: nil, isAuto: KotlinBoolean(bool: true)))
  }

  func markAllRead() -> Completable {
    Completable.from(
      chatAppService
        .readAllMessage(updateToLast: KotlinBoolean(bool: true), isAuto: nil))
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
