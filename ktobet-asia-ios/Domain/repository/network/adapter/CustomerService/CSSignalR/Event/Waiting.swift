import Foundation
import RxSwift
import SharedBu

class Waiting: ChatRoomVisitor {
  private let queueNumber: Int?
  
  init(_ queueNumber: Int? = nil) {
    self.queueNumber = queueNumber
  }
  
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection: SharedBu.Connection) {
    switch connection.status {
    case let status as SharedBu.Connection.StatusConnecting:
      let currentQueueNumber = { [queueNumber] in
        if let queueNumber {
          return Int32(queueNumber)
        }
        else {
          return status.waitInLine <= 1 ? 1 : status.waitInLine - 1
        }
      }()
      
      connection.update(
        connectStatus: SharedBu.Connection.StatusConnecting(waitInLine: currentQueueNumber))
      
    case is SharedBu.Connection.StatusNotExist:
      connection.update(connectStatus: SharedBu.Connection.StatusConnecting(waitInLine: connection.initialWaiting))
      
    case is SharedBu.Connection.StatusClose,
         is SharedBu.Connection.StatusConnected: break
      
    default: break
    }
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
