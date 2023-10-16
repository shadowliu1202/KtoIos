import Foundation
import RxSwift
import sharedbu

class Maintenance: ChatRoomVisitor {
  func visit(config: Config) {
    config.isMaintained = true
  }
  
  func visit(connection _: sharedbu.Connection) {
    // Do nothing
  }
  
  func visit(messageManager _: MessageManager) {
    // Do nothing
  }
}
