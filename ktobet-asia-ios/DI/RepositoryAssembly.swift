import Foundation
import sharedbu
import Swinject

class RepositoryAssembly: Assembly {
  func assemble(container: Container) {
    container.autoregister(PlayerRepository.self, initializer: PlayerRepositoryImpl.init)
    container.autoregister(NotificationRepository.self, initializer: NotificationRepositoryImpl.init)
    container.autoregister(GameInfoRepository.self, initializer: GameInfoRepositoryImpl.init)
    container.autoregister(IAuthRepositoryImpl.self, initializer: IAuthRepositoryImpl.init)
      .implements(IAuthRepository.self, ResetPasswordRepository.self)
    container.autoregister(SystemRepository.self, initializer: SystemRepositoryImpl.init)
    container.autoregister(LocalStorageRepository.self, initializer: LocalStorageRepositoryImpl.init)
    container.autoregister(SettingStore.self, initializer: SettingStore.init)
    container.autoregister(ImageRepository.self, initializer: ImageRepositoryImpl.init)
    container.autoregister(CasinoRecordRepository.self, initializer: CasinoRecordRepositoryImpl.init)
    container.autoregister(CasinoRepository.self, initializer: CasinoRepositoryImpl.init)
    container.autoregister(SlotRepository.self, initializer: SlotRepositoryImpl.init)
    container.autoregister(SlotRecordRepository.self, initializer: SlotRecordRepositoryImpl.init)
    container.autoregister(NumberGameRepository.self, initializer: NumberGameRepositoryImpl.init)
    container.autoregister(NumberGameRecordRepository.self, initializer: NumberGameRecordRepositoryImpl.init)
    container.autoregister(P2PRepository.self, initializer: P2PRepositoryImpl.init)
    container.autoregister(P2PRecordRepository.self, initializer: P2PRecordRepositoryImpl.init)
    container.autoregister(ArcadeRecordRepository.self, initializer: ArcadeRecordRepositoryImpl.init)
    container.autoregister(ArcadeRepository.self, initializer: ArcadeRepositoryImpl.init)
    container.autoregister(PromotionRepository.self, initializer: PromotionRepositoryImpl.init)
    container.autoregister(AccountPatternGenerator.self, initializer: AccountPatternGeneratorFactory.create)
    container.autoregister(LocalizationRepository.self, initializer: LocalizationRepositoryImpl.init)
    container.autoregister(AppUpdateRepository.self, initializer: AppUpdateRepositoryImpl.init)
    container.autoregister(SignalRepository.self, initializer: SignalRepositoryImpl.init)
      .inObjectScope(.locale)
  }
}
