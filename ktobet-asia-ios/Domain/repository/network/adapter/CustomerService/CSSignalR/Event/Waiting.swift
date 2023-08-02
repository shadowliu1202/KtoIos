import Foundation
import RxSwift
import SharedBu

class Waiting: ChatRoomVisitor {
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection: SharedBu.Connection) {
    switch connection.status {
    case let status as SharedBu.Connection.StatusConnecting:
      connection.update(
        connectStatus: SharedBu.Connection.StatusConnecting(waitInLine: status.waitInLine <= 0 ? 1 : status.waitInLine - 1))
      
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
