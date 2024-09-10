import Foundation
import RxSwift
import sharedbu

protocol ArcadeRecordUseCase {
    func getBetSummary() -> Single<BetSummary>
    func getBetSummaryByDate(localDate: String, skip: Int, take: Int) -> Single<[GameGroupedRecord]>
    func getBetRecord(startDate: sharedbu.LocalDateTime, endDate: sharedbu.LocalDateTime, gameId: Int32, skip: Int, take: Int)
        -> Single<[ArcadeGameBetRecord]>

    func getUnsettledSummary() -> Single<[ArcadeUnsettledSummary]>
    func getUnsettledRecords(betTime: sharedbu.LocalDateTime) -> Single<[ArcadeUnsettledRecord]>
}

class ArcadeRecordUseCaseImpl: ArcadeRecordUseCase {
    var arcadeRecordRepository: ArcadeRecordRepository!
    var playerRepository: PlayerRepository!

    init(_ arcadeRecordRepository: ArcadeRecordRepository, _ playerRepository: PlayerRepository) {
        self.arcadeRecordRepository = arcadeRecordRepository
        self.playerRepository = playerRepository
    }

    func getBetSummary() -> Single<BetSummary> {
        let offset = playerRepository.getUtcOffset()
        return offset.flatMap { [unowned self] offset -> Single<BetSummary> in
            arcadeRecordRepository.getBetSummary(zoneOffset: offset)
        }
    }

    func getBetSummaryByDate(localDate: String, skip: Int, take: Int) -> Single<[GameGroupedRecord]> {
        let offset = playerRepository.getUtcOffset()
        return offset.flatMap { [unowned self] offset -> Single<[GameGroupedRecord]> in
            arcadeRecordRepository.getBetSummaryByDate(localDate: localDate, zoneOffset: offset, skip: skip, take: take)
        }
    }

    func getBetRecord(
        startDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32,
        skip: Int,
        take: Int
    )
        -> Single<[ArcadeGameBetRecord]>
    {
        let zoneOffset = playerRepository.getUtcOffset()
        return zoneOffset.flatMap { [unowned self] _ -> Single<[ArcadeGameBetRecord]> in
            arcadeRecordRepository.getBetSummaryByGame(
                beginDate: startDate,
                endDate: endDate,
                gameId: gameId,
                skip: skip,
                take: take
            )
        }
    }
    
    func getUnsettledSummary() -> RxSwift.Single<[ArcadeUnsettledSummary]> {
        let zoneOffset = playerRepository.getUtcOffset()
        return zoneOffset.flatMap({ [unowned self] zoneOffset -> Single<[ArcadeUnsettledSummary]> in
            arcadeRecordRepository.getUnsettledSummary(zoneOffset: zoneOffset)
        })
    }

    func getUnsettledRecords(betTime: LocalDateTime) -> RxSwift.Single<[ArcadeUnsettledRecord]> {
        arcadeRecordRepository.getUnsettledRecords(betTime: betTime)
    }
}
