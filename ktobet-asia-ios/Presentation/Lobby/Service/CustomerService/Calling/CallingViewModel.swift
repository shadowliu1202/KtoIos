import Combine
import sharedbu

protocol CallingViewModelProtocol {
  var currentNumber: Int { get }
  
  func setup(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?)
}

class CallingViewModel:
  ErrorCollectViewModel,
  CallingViewModelProtocol,
  ObservableObject
{
  @Published private(set) var chatRoomStatus: sharedbu.Connection.Status = sharedbu.Connection.StatusNotExist()
  @Published private(set) var currentNumber = 0
  
  @Published var showLeaveMessageAlert = false
  
  private let chatAppService: IChatAppService
  
  private var cancellables = Set<AnyCancellable>()
  
  @Injected private var csViewModel: CustomerServiceViewModel
  
  init(_ chatAppService: IChatAppService) {
    self.chatAppService = chatAppService
    super.init()
  }
  
  func setup(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) {
    getCurrentQueueNumber()
    connectChatRoom(surveyAnswers: surveyAnswers)
  }
  
  private func getCurrentQueueNumber() {
    AnyPublisher.from(chatAppService.observeChatRoom())
      .receive(on: DispatchQueue.main)
      .map { chatRoom in
        if let connecting = chatRoom.status as? sharedbu.Connection.StatusConnecting {
          return Int(connecting.waitInLine)
        }
        else { return 0 }
      }
      .redirectErrors(to: self)
      .assign(to: &$currentNumber)
  }
  
  private func connectChatRoom(surveyAnswers: CustomerServiceDTO.CSSurveyAnswers?) {
    AnyPublisher.from(chatAppService.create(surveyAnswers: surveyAnswers))
      .redirectErrors(to: self)
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)
  }
  
  func closeChatRoom() {
    AnyPublisher.from(chatAppService.exit(forceExit: false))
      .receive(on: DispatchQueue.main)
      .sink(
        receiveCompletion: { [weak self] completion in
          switch completion {
          case .finished:
            break
          case .failure(let error):
            self?.collectError(error)
          }
        },
        receiveValue: { [weak self] _ in
          self?.showLeaveMessageAlert = true
        })
      .store(in: &cancellables)
  }
  
  func getChatRoomStatus() {
    AnyPublisher.from(chatAppService.observeChatRoom())
      .receive(on: DispatchQueue.main)
      .map { $0.status }
      .share()
      .redirectErrors(to: self)
      .assign(to: &$chatRoomStatus)
  }
}
