import Foundation
import sharedbu
import Swinject

class P2pAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(P2PViewModel.self, initializer: P2PViewModel.init)
    container.autoregister(P2PBetViewModel.self, initializer: P2PBetViewModel.init)
    container.autoregister(P2PMyBetProtocol.self, initializer: P2PMyBetAdapter.init)
    container.autoregister(IP2PAppService.self, initializer: ProvideModule.shared.p2pAppService)
  }
}
