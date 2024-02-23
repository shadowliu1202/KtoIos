import Combine
import Foundation
import sharedbu

protocol CallingViewModelProtocol {
  var currentNumber: Int { get }
  
  func setup(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?)
}

extension CustomerServiceDTO.ChatRoom {
  static let NOT_EXIST = CustomerServiceDTO.ChatRoom(
    roomId: "",
    readMessage: [],
    unReadMessage: [],
    status: Connection.StatusNotExist(),
    isMaintained: false)
}

class CallingViewModel:
  ErrorCollectViewModel,
  CallingViewModelProtocol,
  ObservableObject
{
  @Published private(set) var currentNumber = 0
  
  private let chatAppService: IChatAppService
  
  private var chatRoomStream: AnyPublisher<CustomerServiceDTO.ChatRoom, Never>!
  private var cancellables = Set<AnyCancellable>()
  
  init(_ chatAppService: IChatAppService) {
    self.chatAppService = chatAppService
    super.init()
    
    chatRoomStream = AnyPublisher.from(chatAppService.observeChatRoom())
      .subscribe(on: DispatchQueue.global(qos: .background))
      .redirectErrors(to: self)
      .multicast { CurrentValueSubject(.NOT_EXIST) }
      .autoconnect()
      .eraseToAnyPublisher()
  }
  
  func setup(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) {
    getCurrentQueueNumber()
    Task {
      await connectChatRoom(surveyAnswers: surveyAnswers)
    }
  }
  
  private func getCurrentQueueNumber() {
    chatRoomStream
      .receive(on: DispatchQueue.main)
      .map { chatRoom in
        if let connecting = chatRoom.status as? sharedbu.Connection.StatusConnecting {
          return Int(connecting.waitInLine)
        }
        else { return 0 }
      }
      .assign(to: &$currentNumber)
  }
  
  private func connectChatRoom(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) async {
    do {
      try await createChatRoomIfNeeded(surveyAnswers)
    }
    catch {
      collectError(error)
    }
  }
  
  private func createChatRoomIfNeeded(_ surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) async throws {
    guard await !isChatRoomExsit() else { return }
    try await AnyPublisher.from(chatAppService.create(surveyAnswers: surveyAnswers)).value
  }
  
  private func isChatRoomExsit() async -> Bool {
    if let currentChatRoom = await chatRoomStream.first().eraseToAnyPublisher().valueWithoutError {
      return currentChatRoom.status != Connection.StatusNotExist()
    }
    else {
      return false
    }
  }
  
  func getChatRoomStream() -> AnyPublisher<CustomerServiceDTO.ChatRoom, Never> {
    chatRoomStream
  }
  
  func closeChatRoom() async throws {
    try await AnyPublisher.from(chatAppService.exit(forceExit: false)).value
  }
}
