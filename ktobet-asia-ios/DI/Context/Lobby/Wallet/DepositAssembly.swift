import Foundation
import sharedbu
import Swinject

class DepositAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(DepositProtocol.self, initializer: DepositAdapter.init)
    container.autoregister(IDepositAppService.self, initializer: ProvideModule.shared.depositAppService)
      .inObjectScope(.locale)
    
    container.autoregister(CryptoDepositViewModel.self, initializer: CryptoDepositViewModel.init)
    container.autoregister(DepositViewModel.self, initializer: DepositViewModel.init)
    container.autoregister(DepositOfflineConfirmViewModel.self, initializer: DepositOfflineConfirmViewModel.init)
    container.autoregister(DepositRecordDetailViewModel.self, initializer: DepositRecordDetailViewModel.init)
    container.autoregister(StarMergerViewModelImpl.self, initializer: StarMergerViewModelImpl.init)
    container.autoregister(CryptoGuideVNDViewModelImpl.self, initializer: CryptoGuideVNDViewModelImpl.init)
    container.autoregister(DepositCryptoRecordDetailViewModel.self, initializer: DepositCryptoRecordDetailViewModel.init)
    container.autoregister(DepositLogSummaryViewModel.self, initializer: DepositLogSummaryViewModel.init)
    container.autoregister(OfflinePaymentViewModel.self, initializer: OfflinePaymentViewModel.init)
    container.autoregister(OnlinePaymentViewModel.self, initializer: OnlinePaymentViewModel.init)
  }
}
