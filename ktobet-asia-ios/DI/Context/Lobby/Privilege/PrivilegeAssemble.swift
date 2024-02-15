import Foundation
import Swinject

class PrivilegeAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(LevelPrivilegeViewModel.self, initializer: LevelPrivilegeViewModel.init)
  }
}
