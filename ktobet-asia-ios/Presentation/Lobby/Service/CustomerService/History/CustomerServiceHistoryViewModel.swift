import Foundation
import RxCocoa
import RxSwift
import sharedbu

class CustomerServiceHistoryViewModel: CollectErrorViewModel {
  private let chatHistoryAppService: IChatHistoryAppService
  
  private let chatRoomTempMapper = ChatRoomTempMapper()
  
  init(_ chatHistoryAppService: IChatHistoryAppService) {
    self.chatHistoryAppService = chatHistoryAppService
  }
  
  func getChatHistory(roomId: String) -> Observable<[ChatMessage]> {
    Single.from(chatHistoryAppService.getHistory(roomId: roomId)).asObservable()
      .map { [unowned self] in
        guard let DTOChatMessages = $0 as? [CustomerServiceDTO.ChatMessage] else {
          return []
        }
        return chatRoomTempMapper.convertMessages(DTOChatMessages)
      }
      .asObservable()
  }
}
