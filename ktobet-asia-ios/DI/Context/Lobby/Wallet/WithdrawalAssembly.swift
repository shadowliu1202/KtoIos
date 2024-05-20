import Foundation
import sharedbu
import Swinject

class WithdrawalAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(WithdrawalProtocol.self, initializer: WithdrawalAdapter.init)
        container.autoregister(CryptoProtocol.self, initializer: CryptoAdapter.init)
        container.autoregister(IWithdrawalAppService.self, initializer: ProvideModule.shared.withdrawalAppService)
            .inObjectScope(.locale)
    
        container.autoregister(WithdrawalMainViewModel.self, initializer: WithdrawalMainViewModel.init)
        container.autoregister(WithdrawalCryptoLimitViewModel.self, initializer: WithdrawalCryptoLimitViewModel.init)
        container.autoregister(WithdrawalLogSummaryViewModel.self, initializer: WithdrawalLogSummaryViewModel.init)
        container.autoregister(WithdrawalRecordDetailViewModel.self, initializer: WithdrawalRecordDetailViewModel.init)
        container.autoregister(
            WithdrawalCryptoRecordDetailViewModel.self,
            initializer: WithdrawalCryptoRecordDetailViewModel.init)
        container.autoregister(WithdrawalFiatWalletsViewModel.self, initializer: WithdrawalFiatWalletsViewModel.init)
        container.autoregister(WithdrawalFiatRequestStep1ViewModel.self, initializer: WithdrawalFiatRequestStep1ViewModel.init)
        container.autoregister(WithdrawalFiatRequestStep2ViewModel.self, initializer: WithdrawalFiatRequestStep2ViewModel.init)
        container.autoregister(WithdrawalCryptoWalletsViewModel.self, initializer: WithdrawalCryptoWalletsViewModel.init)
        container.autoregister(WithdrawalFiatWalletDetailViewModel.self, initializer: WithdrawalFiatWalletDetailViewModel.init)
        container.autoregister(
            WithdrawalCryptoWalletDetailViewModel.self,
            initializer: WithdrawalCryptoWalletDetailViewModel.init)
        container.autoregister(
            WithdrawalCreateCryptoAccountViewModel.self,
            initializer: WithdrawalCreateCryptoAccountViewModel.init)
        container.autoregister(
            WithdrawalOTPVerifyMethodSelectViewModel.self,
            initializer: WithdrawalOTPVerifyMethodSelectViewModel.init)
        container.autoregister(WithdrawalOTPVerificationViewModel.self, initializer: WithdrawalOTPVerificationViewModel.init)
        container.autoregister(WithdrawalAddFiatBankCardViewModel.self, initializer: WithdrawalAddFiatBankCardViewModel.init)
        container.autoregister(
            WithdrawalCryptoRequestStep1ViewModel.self,
            initializer: WithdrawalCryptoRequestStep1ViewModel.init)
        container.autoregister(
            WithdrawalCryptoRequestStep2ViewModel.self,
            initializer: WithdrawalCryptoRequestStep2ViewModel.init)
        container.autoregister(TurnoverAlertViewModel.self, initializer: TurnoverAlertViewModel.init)
    }
}
