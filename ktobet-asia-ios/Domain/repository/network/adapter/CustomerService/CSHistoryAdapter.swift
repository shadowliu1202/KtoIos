import Foundation
import sharedbu

class CSHistoryAdapter: CSHistoryProtocol {
    private let httpClient: HttpClient

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }
  
    func deleteChatHistories(deleteCsRecords: DeleteCsRecords) -> CompletableWrapper {
        let codable: DeleteCsRecordsCodable = .init(
            roomIds: deleteCsRecords.roomIds,
            isExclude: deleteCsRecords.isExclude)
    
        return httpClient
            .requestJsonString(
                path: "api/room/records",
                method: .put,
                task: .requestJSONEncodable(codable))
            .asReaktiveCompletable()
    }
  
    func getChatHistory(roomId: String) -> SingleWrapper<ResponseItem<ChatHistoryBean_>> {
        httpClient
            .requestJsonString(
                path: "api/room/record/\(roomId)",
                method: .get)
            .asReaktiveResponseItem(serial: ChatHistoryBean_.companion.serializer())
    }
  
    func getRoomHistory(pageIndex: Int32, pageSize: Int32) -> SingleWrapper<ResponseItem<ChatHistories>> {
        httpClient
            .requestJsonString(
                path: "api/room",
                method: .get,
                task: .requestParameters(
                    parameters: [
                        "page": pageIndex,
                        "pageSize": pageSize
                    ]))
            .asReaktiveResponseItem(serial: ChatHistories.companion.serializer())
    }
}
