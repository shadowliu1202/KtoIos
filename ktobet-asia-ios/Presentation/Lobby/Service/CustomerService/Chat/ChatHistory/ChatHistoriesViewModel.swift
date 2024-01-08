import Combine
import Foundation
import sharedbu

protocol ChatHistoriesViewModelProtocol {
  var messages: [CustomerServiceDTO.ChatMessage] { get }
  
  func setup(roomId: String)
}

class ChatHistoriesViewModel:
  ErrorCollectViewModel,
  ChatHistoriesViewModelProtocol,
  ObservableObject
{
  @Published private(set) var messages: [CustomerServiceDTO.ChatMessage] = []
  
  private let chatHistoryAppService: IChatHistoryAppService
  private let playerConfiguration: PlayerConfiguration
  
  init(
    _ chatHistoryAppService: IChatHistoryAppService,
    _ playerConfiguration: PlayerConfiguration)
  {
    self.chatHistoryAppService = chatHistoryAppService
    self.playerConfiguration = playerConfiguration
  }
  
  func setup(roomId: String) {
    getChatHistory(roomId: roomId)
  }
  
  private func getChatHistory(roomId: String) {
    AnyPublisher.from(chatHistoryAppService.getHistory(roomId: roomId))
      .map { $0 as? [CustomerServiceDTO.ChatMessage] ?? [] }
      .redirectErrors(to: self)
      .assign(to: &$messages)
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
