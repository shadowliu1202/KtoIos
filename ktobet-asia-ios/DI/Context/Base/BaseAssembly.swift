import Foundation
import sharedbu
import Swinject
import SwinjectAutoregistration

class BaseAssembly: Assembly {
    func assemble(container: Container) {
        container
            .register(PlayerConfiguration.self) { PlayerConfigurationImpl(($0 ~> LocalStorageRepository.self).getCultureCode()) }
        container.register(SupportLocale.self) { ($0 ~> PlayerConfiguration.self).supportLocale }
            .inObjectScope(.locale)
        container.autoregister(LocalizeUtils.self, initializer: LocalizeUtils.init)
            .implements(StringSupporter.self)
            .inObjectScope(.locale)
        container.register(AlertProtocol.self) { _ in Alert.shared }
            .inObjectScope(.container)
        container.register(Loading.self) { _ in LoadingImpl.shared }
            .inObjectScope(.container)
        container.register(SnackBar.self) { _ in SnackBarImpl.shared }
            .inObjectScope(.container)
        container.autoregister(ActivityIndicator.self, name: "CheckingIsLogged", initializer: ActivityIndicator.init)
            .inObjectScope(.container)
        container.register(INetworkMonitor.self) { _ in NetworkStateMonitor.shared }
            .inObjectScope(.container)
        container.autoregister(MemoryCacheImpl.self, initializer: MemoryCacheImpl.init)
            .inObjectScope(.locale)
        container.autoregister(ApplicationStorable.self, initializer: ApplicationStorage.init)
            .inObjectScope(.container)
        container.autoregister(KeychainStorable.self, initializer: Keychain.init)
            .inObjectScope(.container)
        container.autoregister(ImageProtocol.self, initializer: ImageAdapter.init)
        container.autoregister(CommonProtocol.self, initializer: CommonAdapter.init)
        viewModels(container: container)
        stringServices(container: container)
    }

    private func stringServices(container: Container) {
        container.autoregister(ExternalStringService.self, initializer: ExternalStringServiceFactory.init)
            .inObjectScope(.locale)
        container.register(DepositStringService.self, factory: { ($0 ~> ExternalStringService.self).deposit() })
            .inObjectScope(.locale)
        container.register(CasinoStringService.self, factory: { ($0 ~> ExternalStringService.self).casino() })
            .inObjectScope(.locale)
        container.register(P2PStringService.self, factory: { ($0 ~> ExternalStringService.self).p2p() })
            .inObjectScope(.locale)
    }

    private func viewModels(container: Container) {
        container.autoregister(NavigationViewModel.self, initializer: NavigationViewModel.init)
        container.autoregister(ServiceStatusViewModel.self, initializer: ServiceStatusViewModel.init)
        container.autoregister(MaintenanceViewModel.self, initializer: MaintenanceViewModel.init)
            .inObjectScope(.locale)
        container.autoregister(CommonOtpViewModel.self, initializer: CommonOtpViewModel.init)
        container.autoregister(TermsViewModel.self, initializer: TermsViewModel.init)
            .inObjectScope(.locale)
        container.autoregister(ConfigurationViewModel.self, initializer: ConfigurationViewModel.init)
        container.autoregister(AppSynchronizeViewModel.self, initializer: AppSynchronizeViewModel.init)
            .inObjectScope(.container)
    }
}
