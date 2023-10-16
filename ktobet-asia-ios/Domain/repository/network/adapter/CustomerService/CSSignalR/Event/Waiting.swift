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
  
  func visit(connection: sharedbu.Connection) {
    switch connection.status {
    case let status as sharedbu.Connection.StatusConnecting:
      let currentQueueNumber = { [queueNumber] in
        if let queueNumber {
          return Int32(queueNumber)
        }
        else {
          return status.waitInLine <= 1 ? 1 : status.waitInLine - 1
        }
      }()
      
      connection.update(
        connectStatus: sharedbu.Connection.StatusConnecting(waitInLine: currentQueueNumber))
      
    case is sharedbu.Connection.StatusNotExist:
      connection.update(connectStatus: sharedbu.Connection.StatusConnecting(waitInLine: connection.initialWaiting))
      
    case is sharedbu.Connection.StatusClose,
         is sharedbu.Connection.StatusConnected: break
      
    default: break
    }
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
