import Foundation
import RxSwift
import sharedbu

class Close: ChatRoomVisitor {
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection: sharedbu.Connection) {
    connection.update(connectStatus: sharedbu.Connection.StatusClose())
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
