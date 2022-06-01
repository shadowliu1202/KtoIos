import Foundation
import SharedBu
import RxSwift

protocol SlotRecordUseCase {
    func getBetSummary() -> Single<BetSummary>
    func getSlotGameRecordByDate(localDate: String) -> Single<[SlotGroupedRecord]>
    func getBetRecordByPage(startDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32, offset: Int, take: Int) -> Single<CommonPage<SlotBetRecord>>
    func getUnsettledSummary() -> Single<[SlotUnsettledSummary]>
    func getUnsettledRecords(betTime: SharedBu.LocalDateTime, offset: Int, take: Int) -> Single<CommonPage<SlotUnsettledRecord>>
}

class SlotRecordUseCaseImpl: SlotRecordUseCase {
    var slotRecordRepository : SlotRecordRepository!
    var playerRepository : PlayerRepository!
    
    init(_ slotRecordRepository : SlotRecordRepository, playerRepository : PlayerRepository) {
        self.slotRecordRepository = slotRecordRepository
        self.playerRepository = playerRepository
    }
    
    func getBetSummary() -> Single<BetSummary> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap { [unowned self] (offset) -> Single<BetSummary> in
            return self.slotRecordRepository.getBetSummary(zoneOffset: offset)
        }
    }
    
    func getSlotGameRecordByDate(localDate: String) -> Single<[SlotGroupedRecord]> {
        let offset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return offset.flatMap { [unowned self] (offset) -> Single<[SlotGroupedRecord]> in
            return self.slotRecordRepository.getBetSummaryByDate(localDate: localDate, zoneOffset: offset)
        }
    }
    
    func getBetRecordByPage(startDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32, offset: Int, take: Int) -> Single<CommonPage<SlotBetRecord>> {
        slotRecordRepository.getBetRecords(startDate: startDate, endDate: endDate, gameId: gameId, offset: offset, take: take)
    }
    
    func getUnsettledSummary() -> Single<[SlotUnsettledSummary]> {
        let zoneOffset = playerRepository.loadPlayer().map{ $0.zoneOffset() }
        return zoneOffset.flatMap({ [unowned self] (zoneOffset) -> Single<[SlotUnsettledSummary]> in
            return slotRecordRepository.getUnsettledSummary(zoneOffset: zoneOffset)
        })
        
    }
    
    func getUnsettledRecords(betTime: SharedBu.LocalDateTime, offset: Int, take: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
        return slotRecordRepository.getUnsettledRecords(betTime: betTime, offset: offset, take: take)
    }
}

