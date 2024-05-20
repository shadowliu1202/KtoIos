import Foundation
import RxSwift
import sharedbu

protocol P2PRecordUseCase {
    func getBetSummary() -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String) -> Single<[GameGroupedRecord]>
    func getBetRecord(startDate: sharedbu.LocalDateTime, endDate: sharedbu.LocalDateTime, gameId: Int32)
        -> Single<[P2PGameBetRecord]>
}

class P2PRecordUseCaseImpl: P2PRecordUseCase {
    var p2pRecordRepository: P2PRecordRepository!
    var playerRepository: PlayerRepository!

    init(_ p2pRecordRepository: P2PRecordRepository, _ playerRepository: PlayerRepository) {
        self.p2pRecordRepository = p2pRecordRepository
        self.playerRepository = playerRepository
    }

    func getBetSummary() -> Single<[DateSummary]> {
        playerRepository
            .getUtcOffset()
            .flatMap { [unowned self] offset -> Single<[DateSummary]> in
                self.p2pRecordRepository.getBetSummary(zoneOffset: offset)
            }
    }

    func getBetSummaryByDate(localDate: String) -> Single<[GameGroupedRecord]> {
        playerRepository
            .getUtcOffset()
            .flatMap { [unowned self] offset -> Single<[GameGroupedRecord]> in
                self.p2pRecordRepository.getBetSummaryByDate(localDate: localDate, zoneOffset: offset)
            }
    }

    func getBetRecord(
        startDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32)
        -> Single<[P2PGameBetRecord]>
    {
        p2pRecordRepository.getBetSummaryByGame(
            beginDate: startDate,
            endDate: endDate,
            gameId: gameId)
    }
}
