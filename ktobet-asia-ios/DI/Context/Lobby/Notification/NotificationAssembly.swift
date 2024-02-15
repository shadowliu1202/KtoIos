import Foundation
import Swinject

class NotificationAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(NotificationViewModel.self, initializer: NotificationViewModel.init)
  }
}
