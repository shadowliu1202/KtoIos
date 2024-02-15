import Foundation
import Swinject

class ResetPasswordAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(ResetPasswordViewModel.self, initializer: ResetPasswordViewModel.init)
  }
}
