import Foundation
import sharedbu
import Swinject

class NumberGameAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(NumberGameViewModel.self, initializer: NumberGameViewModel.init)
        container.autoregister(NumberGameRecordViewModel.self, initializer: NumberGameRecordViewModel.init)
        container.autoregister(NumberGameProtocol.self, initializer: NumberGameAdapter.init)
        container.autoregister(INumberGameAppService.self, initializer: ProvideModule.shared.numberGameAppService)
    }
}
