import Foundation
import RxSwift
import SharedBu

class Close: ChatRoomVisitor {
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection: SharedBu.Connection) {
    connection.update(connectStatus: SharedBu.Connection.StatusClose())
  }
  
  func visit(messageManager: MessageManager) {
    // Do nothing
  }
}
