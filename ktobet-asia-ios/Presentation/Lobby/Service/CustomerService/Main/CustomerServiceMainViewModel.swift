import Combine
import Foundation
import sharedbu

protocol CustomerServiceMainViewModelProtocol {
  var isChatRoomExist: Bool { get }
  var histories: [CustomerServiceDTO.ChatHistoriesHistory] { get }
  
  func hasPreChatSurvey() async -> Bool
  func getMoreHistories()
  func refreshData()
  func setup()
}

class CustomerServiceMainViewModel:
  ErrorCollectViewModel,
  CustomerServiceMainViewModelProtocol,
  ObservableObject
{
  @Published private(set) var isChatRoomExist = true
  @Published private(set) var histories: [CustomerServiceDTO.ChatHistoriesHistory] = []
  
  private let chatHistoryAppService: IChatHistoryAppService
  private let chatAppService: IChatAppService
  private let surveyAppService: ISurveyAppService
  
  private let pageSize = 20
  
  private var cancellables = Set<AnyCancellable>()
  private var page = 1
  private var itemsTotalCount = 0
  
  init(
    _ chatHistoryAppService: IChatHistoryAppService,
    _ chatAppService: IChatAppService,
    _ surveyAppService: ISurveyAppService)
  {
    self.chatHistoryAppService = chatHistoryAppService
    self.chatAppService = chatAppService
    self.surveyAppService = surveyAppService
  }
  
  func setup() {
    getIsChatRoomExist()
  }
  
  private func getIsChatRoomExist() {
    AnyPublisher.from(chatAppService.observeChatRoom())
      .subscribe(on: DispatchQueue.global(qos: .background))
      .receive(on: DispatchQueue.main)
      .map { $0.status != sharedbu.Connection.StatusNotExist() }
      .redirectErrors(to: self)
      .assign(to: &$isChatRoomExist)
  }
  
  private func getChatHistories(page: Int) {
    AnyPublisher.from(
      chatHistoryAppService.getHistories(
        page: Int32(page),
        pageSize: Int32(pageSize)))
      .receive(on: DispatchQueue.main)
      .handleEvents(receiveOutput: { [unowned self] in
        itemsTotalCount = Int($0.totalCount)
      })
      .map { [unowned self] in
        if itemsTotalCount <= pageSize {
          return $0.histories
        }
        else {
          return itemsTotalCount == histories.count ? histories : histories + $0.histories
        }
      }
      .redirectErrors(to: self)
      .assign(to: &$histories)
  }
  
  func getMoreHistories() {
    if isMoreItemRemaining(itemsLoadedCount: histories.count, totalItems: itemsTotalCount) {
      page += 1
      getChatHistories(page: page)
    }
  }
  
  private func isMoreItemRemaining(itemsLoadedCount: Int, totalItems: Int) -> Bool {
    itemsLoadedCount < totalItems
  }
  
  func refreshData() {
    histories = []
    itemsTotalCount = 0
    getChatHistories(page: 1)
  }
  
  func hasPreChatSurvey() async -> Bool {
    await AnyPublisher.from(surveyAppService.hasPreChatSurvey())
      .map { $0.toBool() }
      .tryCatch { error in
        if error is ServiceUnavailableException {
          return Just(false)
        }
        else {
          throw error
        }
      }
      .redirectErrors(to: self)
      .valueWithoutError ?? false
  }
}
