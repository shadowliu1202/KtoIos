import Foundation
import sharedbu
import Swinject
import SwinjectAutoregistration

class PromotionAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(PromotionViewModel.self, initializer: PromotionViewModel.init)
    container.autoregister(PromotionHistoryViewModel.self, initializer: PromotionHistoryViewModel.init)
    container.autoregister(PromotionProtocol.self, initializer: PromotionAdapter.init)
  }
}
