import Foundation
import sharedbu

class CSHistoryAdapter: CSHistoryProtocol {
  private let chatHistoryAPI: ChatHistoryAPI
  
  init(_ chatHistoryAPI: ChatHistoryAPI) {
    self.chatHistoryAPI = chatHistoryAPI
  }
  
  func deleteChatHistories(deleteCsRecords: DeleteCsRecords) -> CompletableWrapper {
    chatHistoryAPI
      .deleteChatHistories(deleteCsRecords: deleteCsRecords)
      .asReaktiveCompletable()
  }
  
  func getChatHistory(roomId: String) -> SingleWrapper<ResponseItem<ChatHistoryBean_>> {
    chatHistoryAPI
      .getChatHistory(roomId: roomId)
      .asReaktiveResponseItem(serial: ChatHistoryBean_.companion.serializer())
  }
  
  func getRoomHistory(pageIndex: Int32, pageSize: Int32) -> SingleWrapper<ResponseItem<ChatHistories>> {
    chatHistoryAPI
      .getPlayerChatHistory(pageIndex: pageIndex, pageSize: pageSize)
      .asReaktiveResponseItem(serial: ChatHistories.companion.serializer())
  }
}
