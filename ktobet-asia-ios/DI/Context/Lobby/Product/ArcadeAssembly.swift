import Foundation
import sharedbu
import Swinject

class ArcadeAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(ArcadeRecordViewModel.self, initializer: ArcadeRecordViewModel.init)
        container.autoregister(ArcadeViewModel.self, initializer: ArcadeViewModel.init)
        container.autoregister(ArcadeProtocol.self, initializer: ArcadeAdapter.init)
        container.autoregister(IArcadeAppService.self, initializer: ProvideModule.shared.arcadeAppService)
    }
}
