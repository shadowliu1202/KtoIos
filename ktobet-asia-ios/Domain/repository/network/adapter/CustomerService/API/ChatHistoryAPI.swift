import Foundation
import RxSwift
import SharedBu

class ChatHistoryAPI {
  private let httpClient: HttpClient

  init(_ httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func getPlayerChatHistory(pageIndex: Int32, pageSize: Int32) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "api/room",
        method: .get,
        task: .requestParameters(
          parameters: [
            "page": pageIndex,
            "pageSize": pageSize
          ]))
  }
  
  func deleteChatHistories(deleteCsRecords: DeleteCsRecords) -> Single<String> {
    let codable: DeleteCsRecordsCodable = .init(
      roomIds: deleteCsRecords.roomIds,
      isExclude: deleteCsRecords.isExclude)
    
    return httpClient
      .requestJsonString(
        path: "api/room/records",
        method: .put,
        task: .requestJSONEncodable(codable))
  }
  
  func getChatHistory(roomId: RoomId) -> Single<String> {
    httpClient
      .requestJsonString(
        path: "api/room/record/\(roomId)",
        method: .get)
  }
}
