import Foundation
import sharedbu
import Swinject

class CasinoAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(CasinoViewModel.self, initializer: CasinoViewModel.init)
        container.autoregister(CasinoGameProtocol.self, initializer: CasinoGameAdapter.init)
        container.autoregister(CasinoMyBetProtocol.self, initializer: CasinoMyBetAdapter.init)
        container.autoregister(ICasinoAppService.self, initializer: ProvideModule.shared.casinoAppService)
            .implements(ICasinoGameAppService.self, ICasinoMyBetAppService.self)
    }
}
