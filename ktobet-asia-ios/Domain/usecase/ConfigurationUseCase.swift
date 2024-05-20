import Foundation
import RxSwift
import sharedbu

protocol ConfigurationUseCase {
    func locale() -> SupportLocale
    func getOtpRetryCount() -> Int
    func setOtpRetryCount(_ count: Int)
}

class ConfigurationUseCaseImpl: ConfigurationUseCase {
    private let playerRepo: PlayerRepository
    private let localStorageRepository: LocalStorageRepository
    private let playerConfiguration: PlayerConfiguration

    init(
        _ playerRepo: PlayerRepository,
        _ localStorageRepository: LocalStorageRepository,
        _ playerConfiguration: PlayerConfiguration)
    {
        self.playerRepo = playerRepo
        self.localStorageRepository = localStorageRepository
        self.playerConfiguration = playerConfiguration
    }

    func locale() -> SupportLocale {
        playerConfiguration.supportLocale
    }

    func getOtpRetryCount() -> Int {
        localStorageRepository.getRetryCount()
    }

    func setOtpRetryCount(_ count: Int) {
        localStorageRepository.setRetryCount(count)
    }
}
