import Foundation
import RxSwift
import sharedbu

class Waiting: ChatRoomVisitor {
  private let queueNumber: Int?
  
  init(_ queueNumber: Int? = nil) {
    self.queueNumber = queueNumber
  }
  
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection: Connection) {
    switch onEnum(of: connection.status) {
    case .connecting(let it):
      let currentQueueNumber = { [queueNumber] in
        if let queueNumber {
          return Int32(queueNumber)
        }
        else {
          return it.waitInLine <= 1 ? 1 : it.waitInLine - 1
        }
      }()
      
      connection.update(connectStatus: Connection.StatusConnecting(waitInLine: currentQueueNumber))
    case .notExist:
      connection.update(connectStatus: Connection.StatusConnecting(waitInLine: connection.initialWaiting))
      
    case .close,
         .connected:
      break
    }
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
