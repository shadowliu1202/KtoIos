import Foundation
import sharedbu
import Swinject

class SlotAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(SlotViewModel.self, initializer: SlotViewModel.init)
    container.autoregister(SlotBetViewModel.self, initializer: SlotBetViewModel.init)
  }
}
