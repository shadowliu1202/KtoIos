import Foundation
import sharedbu
import Swinject

class CustomerServiceAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(CSEventService.self, initializer: CSEventServiceAdapter.init)
      .inObjectScope(.locale)
    container.autoregister(CustomerServiceProtocol.self, initializer: CSAdapter.init)
      .inObjectScope(.locale)
    container.autoregister(CSSurveyProtocol.self, initializer: CSSurveyAdapter.init)
      .inObjectScope(.locale)
    container.autoregister(CSHistoryProtocol.self, initializer: CSHistoryAdapter.init)
      .inObjectScope(.locale)
    container.autoregister(ICustomerServiceAppService.self, initializer: ProvideModule.shared.csAppService)
      .implements(IChatAppService.self, ISurveyAppService.self, IChatHistoryAppService.self)
      .inObjectScope(.locale)
    container.autoregister(CustomServicePresenter.self, initializer: CustomServicePresenter.init)
      .inObjectScope(.locale)
    
    viewModels(container: container)
  }
  
  private func viewModels(container: Container) {
    container.autoregister(CustomerServiceViewModel.self, initializer: CustomerServiceViewModel.init)
      .inObjectScope(.locale)
    container.autoregister(ChatHistoriesViewModel.self, initializer: ChatHistoriesViewModel.init)
    container.autoregister(ChatHistoriesEditViewModel.self, initializer: ChatHistoriesEditViewModel.init)
    container.autoregister(ChatRoomViewModel.self, initializer: ChatRoomViewModel.init)
      .inObjectScope(.locale)
    container.autoregister(ChattingListViewModel.self, initializer: ChattingListViewModel.init)
      .inObjectScope(.locale)
    container.autoregister(PrechatSurveyViewModel.self, initializer: PrechatSurveyViewModel.init)
    container.autoregister(ExitSurveyViewModel.self, initializer: ExitSurveyViewModel.init)
    container.autoregister(CustomerServiceMainViewModel.self, initializer: CustomerServiceMainViewModel.init)
      .inObjectScope(.locale)
    container.autoregister(CallingViewModel.self, initializer: CallingViewModel.init)
    container.autoregister(OfflineMessageViewModel.self, initializer: OfflineMessageViewModel.init)
      .inObjectScope(.locale)
  }
}
  