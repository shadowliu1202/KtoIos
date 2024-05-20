import Foundation
import Swinject
import SwinjectAutoregistration

class ApiAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(NotificationApi.self, initializer: NotificationApi.init)
        container.autoregister(AuthenticationApi.self, initializer: AuthenticationApi.init)
        container.autoregister(PlayerApi.self, initializer: PlayerApi.init)
        container.autoregister(VersionUpdateApi.self, initializer: VersionUpdateApi.init)
        container.register(VersionUpdateApi.self) { VersionUpdateApi($0 ~> (HttpClient.self, name: "update")) }
        container.autoregister(PortalApi.self, initializer: PortalApi.init)
        container.autoregister(GameApi.self, initializer: GameApi.init)
        container.autoregister(BankApi.self, initializer: BankApi.init)
        container.autoregister(ImageApi.self, initializer: ImageApi.init)
        container.autoregister(CasinoApi.self, initializer: CasinoApi.init)
        container.autoregister(DepositAPI.self, initializer: DepositAPI.init)
        container.autoregister(CasinoMyBetAPI.self, initializer: CasinoMyBetAPI.init)
        container.autoregister(SlotApi.self, initializer: SlotApi.init)
        container.autoregister(NumberGameApi.self, initializer: NumberGameApi.init)
        container.autoregister(P2PApi.self, initializer: P2PApi.init)
        container.autoregister(P2PMyBetAPI.self, initializer: P2PMyBetAPI.init)
        container.autoregister(ArcadeApi.self, initializer: ArcadeApi.init)
        container.autoregister(PromotionApi.self, initializer: PromotionApi.init)
        container.autoregister(CommonAPI.self, initializer: CommonAPI.init)
        container.autoregister(CryptoAPI.self, initializer: CryptoAPI.init)
        container.autoregister(WithdrawalAPI.self, initializer: WithdrawalAPI.init)
    }
}
