import Foundation
import share_bu
import RxSwift

protocol CasinoRecordUseCase {
    func getBetSummary() -> Single<BetSummary>
    func getUnsettledSummary() -> Single<[UnsettledBetSummary]>
    func getUnsettledRecords(date: String) -> Single<[UnsettledBetRecord]>
    func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]>
    func getBetRecords(periodOfRecord: PeriodOfRecord) -> Single<[BetRecord]>
    func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?>
}

class CasinoRecordUseCaseImpl: CasinoRecordUseCase {
    var casinoRecordRepository : CasinoRecordRepository!
    var playerRepository : PlayerRepository!
    
    init(_ casinoRecordRepository : CasinoRecordRepository, playerRepository : PlayerRepository) {
        self.casinoRecordRepository = casinoRecordRepository
        self.playerRepository = playerRepository
    }
    
    func getBetSummary() -> Single<BetSummary> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap {[unowned self] (offset) -> Single<BetSummary> in
            return self.casinoRecordRepository.getBetSummary(zoneOffset: offset)
        }
    }
    
    func getUnsettledSummary() -> Single<[UnsettledBetSummary]> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap {[unowned self] (offset) -> Single<[UnsettledBetSummary]> in
            return self.casinoRecordRepository.getUnsettledSummary(zoneOffset: offset)
        }
    }
    
    func getUnsettledRecords(date: String) -> Single<[UnsettledBetRecord]> {
        return casinoRecordRepository.getUnsettledRecords(date: date)
    }
    
    func getBetSummaryByDate(localDate: String) -> Single<[PeriodOfRecord]> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap {[unowned self] (offset) -> Single<[PeriodOfRecord]> in
            return self.casinoRecordRepository.getPeriodRecords(localDate: localDate,zoneOffset: offset)
        }
    }
    
    func getBetRecords(periodOfRecord: PeriodOfRecord) -> Single<[BetRecord]> {
        return casinoRecordRepository.getBetRecords(periodOfRecord: periodOfRecord)
    }
    
    func getCasinoWagerDetail(wagerId: String) -> Single<CasinoDetail?> {
        return casinoRecordRepository.getCasinoWagerDetail(wagerId: wagerId)
    }
}
