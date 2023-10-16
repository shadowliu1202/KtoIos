import Foundation
import RxSwift
import sharedbu

protocol ArcadeRecordUseCase {
  func getBetSummary() -> Single<[DateSummary]>
  func getBetSummaryByDate(localDate: String, skip: Int, take: Int) -> Single<[GameGroupedRecord]>
  func getBetRecord(startDate: sharedbu.LocalDateTime, endDate: sharedbu.LocalDateTime, gameId: Int32, skip: Int, take: Int)
    -> Single<[ArcadeGameBetRecord]>
}

class ArcadeRecordUseCaseImpl: ArcadeRecordUseCase {
  var arcadeRecordRepository: ArcadeRecordRepository!
  var playerRepository: PlayerRepository!

  init(_ arcadeRecordRepository: ArcadeRecordRepository, _ playerRepository: PlayerRepository) {
    self.arcadeRecordRepository = arcadeRecordRepository
    self.playerRepository = playerRepository
  }

  func getBetSummary() -> Single<[DateSummary]> {
    let offset = playerRepository.getUtcOffset()
    return offset.flatMap { [unowned self] offset -> Single<[DateSummary]> in
      self.arcadeRecordRepository.getBetSummary(zoneOffset: offset)
    }
  }

  func getBetSummaryByDate(localDate: String, skip: Int, take: Int) -> Single<[GameGroupedRecord]> {
    let offset = playerRepository.getUtcOffset()
    return offset.flatMap { [unowned self] offset -> Single<[GameGroupedRecord]> in
      self.arcadeRecordRepository.getBetSummaryByDate(localDate: localDate, zoneOffset: offset, skip: skip, take: take)
    }
  }

  func getBetRecord(
    startDate: sharedbu.LocalDateTime,
    endDate: sharedbu.LocalDateTime,
    gameId: Int32,
    skip: Int,
    take: Int) -> Single<[ArcadeGameBetRecord]>
  {
    let zoneOffset = playerRepository.getUtcOffset()
    return zoneOffset.flatMap { [unowned self] _ -> Single<[ArcadeGameBetRecord]> in
      self.arcadeRecordRepository.getBetSummaryByGame(
        beginDate: startDate,
        endDate: endDate,
        gameId: gameId,
        skip: skip,
        take: take)
    }
  }
}
