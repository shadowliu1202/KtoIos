import Foundation
import RxSwift
import SharedBu

protocol CasinoRecordUseCase {
  func getBetSummary() -> Single<BetSummary>
  func getUnsettledSummary() -> Single<[UnsettledBetSummary]>
  func getUnsettledRecords(date: SharedBu.LocalDateTime) -> Single<[UnsettledBetRecord]>
  func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]>
  func getBetRecords(periodOfRecord: PeriodOfRecord, offset: Int) -> Single<[BetRecord]>
  func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?>
}

class CasinoRecordUseCaseImpl: CasinoRecordUseCase {
  var casinoRecordRepository: CasinoRecordRepository!
  var playerRepository: PlayerRepository!

  init(_ casinoRecordRepository: CasinoRecordRepository, playerRepository: PlayerRepository) {
    self.casinoRecordRepository = casinoRecordRepository
    self.playerRepository = playerRepository
  }

  func getBetSummary() -> Single<BetSummary> {
    let offset = playerRepository.getUtcOffset()
    return offset.flatMap { [unowned self] offset -> Single<BetSummary> in
      self.casinoRecordRepository.getBetSummary(zoneOffset: offset)
    }
  }

  func getUnsettledSummary() -> Single<[UnsettledBetSummary]> {
    let offset = playerRepository.getUtcOffset()
    return offset.flatMap { [unowned self] offset -> Single<[UnsettledBetSummary]> in
      self.casinoRecordRepository.getUnsettledSummary(zoneOffset: offset)
    }
  }

  func getUnsettledRecords(date: SharedBu.LocalDateTime) -> Single<[UnsettledBetRecord]> {
    casinoRecordRepository.getUnsettledRecords(date: date)
  }

  func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]> {
    let offset = playerRepository.getUtcOffset()
    return offset.flatMap { [unowned self] offset -> Single<[PeriodOfRecord]> in
      self.casinoRecordRepository.getPeriodRecords(localDate: localDate, zoneOffset: offset)
    }
  }

  func getBetRecords(periodOfRecord: PeriodOfRecord, offset: Int) -> Single<[BetRecord]> {
    casinoRecordRepository.getBetRecords(periodOfRecord: periodOfRecord, offset: offset)
  }

  func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?> {
    casinoRecordRepository.getCasinoWagerDetail(wagerId: wagerId)
  }
}
