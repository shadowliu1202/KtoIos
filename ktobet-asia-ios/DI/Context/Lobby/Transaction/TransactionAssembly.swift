import Foundation
import sharedbu
import Swinject

class TransactionAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(TransactionLogViewModel.self, initializer: TransactionLogViewModel.init)
        container.autoregister(CashProtocol.self, initializer: CashAdapter.init)
        container.autoregister(TransactionResource.self, initializer: TransactionResourceAdapter.init)
        container.autoregister(ITransactionAppService.self, initializer: ProvideModule.shared.transactionAppService)
    }
}
