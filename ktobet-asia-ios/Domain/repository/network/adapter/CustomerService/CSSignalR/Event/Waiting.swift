import Foundation
import RxSwift
import SharedBu

class Waiting: ChatRoomVisitor {
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection: SharedBu.Connection) {
    guard let connectingStatus = connection.status as? SharedBu.Connection.StatusConnecting else {
      connection.update(connectStatus: SharedBu.Connection.StatusConnecting(waitInLine: connection.initialWaiting))
      return
    }
    let waitInLine = connectingStatus.waitInLine <= 0 ? 1 : connectingStatus.waitInLine - 1
    connection.update(connectStatus: SharedBu.Connection.StatusConnecting(waitInLine: waitInLine))
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
