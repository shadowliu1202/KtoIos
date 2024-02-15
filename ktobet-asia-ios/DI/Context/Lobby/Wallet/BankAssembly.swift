import Foundation
import sharedbu
import Swinject

class BankAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(BankAppService.self, initializer: ProvideModule.shared.bankAppService)
  }
}
