import Foundation
import sharedbu
import Swinject

class UseCaseAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(RegisterUseCase.self, initializer: RegisterUseCaseImpl.init)
        container.autoregister(ConfigurationUseCase.self, initializer: ConfigurationUseCaseImpl.init)
        container.autoregister(AuthenticationUseCase.self, initializer: AuthenticationUseCaseImpl.init)
        container.autoregister(ISystemStatusUseCase.self, initializer: SystemStatusUseCase.init)
        container.autoregister(ResetPasswordUseCase.self, initializer: ResetPasswordUseCaseImpl.init)
        container.autoregister(PlayerDataUseCase.self, initializer: PlayerDataUseCaseImpl.init)
        container.autoregister(NotificationUseCase.self, initializer: NotificationUseCaseImpl.init)
        container.autoregister(UploadImageUseCase.self, initializer: UploadImageUseCaseImpl.init)
        container.autoregister(CasinoRecordUseCase.self, initializer: CasinoRecordUseCaseImpl.init)
        container.autoregister(CasinoUseCase.self, initializer: CasinoUseCaseImpl.init)
        container.autoregister(SlotUseCase.self, initializer: SlotUseCaseImpl.init)
        container.autoregister(SlotRecordUseCase.self, initializer: SlotRecordUseCaseImpl.init)
        container.autoregister(NumberGameUseCase.self, initializer: NumberGameUseCasaImp.init)
        container.autoregister(NumberGameRecordUseCase.self, initializer: NumberGameRecordUseCaseImpl.init)
        container.autoregister(P2PUseCase.self, initializer: P2PUseCaseImpl.init)
        container.autoregister(P2PRecordUseCase.self, initializer: P2PRecordUseCaseImpl.init)
        container.autoregister(ArcadeRecordUseCase.self, initializer: ArcadeRecordUseCaseImpl.init)
        container.autoregister(ArcadeUseCase.self, initializer: ArcadeUseCaseImpl.init)
        container.autoregister(PromotionUseCase.self, initializer: PromotionUseCaseImpl.init)
        container.autoregister(LocalizationPolicyUseCase.self, initializer: LocalizationPolicyUseCaseImpl.init)
        container.autoregister(AppVersionUpdateUseCase.self, initializer: AppVersionUpdateUseCaseImpl.init)
    }
}
