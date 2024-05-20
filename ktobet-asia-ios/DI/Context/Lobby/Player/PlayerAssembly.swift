import Foundation
import sharedbu
import Swinject

class PlayerAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(ModifyProfileViewModel.self, initializer: ModifyProfileViewModel.init)
        container.autoregister(DefaultProductViewModel.self, initializer: DefaultProductViewModel.init)
        container.autoregister(PlayerViewModel.self, initializer: PlayerViewModel.init)
        container.autoregister(PlayerProtocol.self, initializer: PlayerAdapter.init)
        container.autoregister(DefaultProductProtocol.self, initializer: DefaultProductAdapter.init)
        container.autoregister(DefaultProductAppService.self, initializer: ProvideModule.shared.defaultProductAppService)
    }
}
