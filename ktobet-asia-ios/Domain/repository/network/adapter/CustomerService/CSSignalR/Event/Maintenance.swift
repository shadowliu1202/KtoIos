import Foundation
import RxSwift
import SharedBu

class Maintenance: ChatRoomVisitor {
  func visit(config: Config) {
    config.isMaintained = true
  }
  
  func visit(connection _: SharedBu.Connection) {
    // Do nothing
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
