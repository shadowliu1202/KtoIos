import Foundation
import RxSwift
import SharedBu

protocol SlotRecordRepository {
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<BetSummary>
    func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[SlotGroupedRecord]>
    func getBetRecords(startDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32, offset: Int, take: Int) -> Single<CommonPage<SlotBetRecord>>
    func getUnsettledSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[SlotUnsettledSummary]>
    func getUnsettledRecords(betTime: SharedBu.LocalDateTime, offset: Int, take: Int) -> Single<CommonPage<SlotUnsettledRecord>>
}

class SlotRecordRepositoryImpl: SlotRecordRepository {
    private var slotApi: SlotApi!
    private var playerConfiguation: PlayerConfiguration!
    
    init(_ slotApi: SlotApi, playerConfiguation: PlayerConfiguration) {
        self.slotApi = slotApi
        self.playerConfiguation = playerConfiguation
    }
    
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<BetSummary> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return slotApi.getSlotBetSummary(offset: secondsToHours).map { (response) -> BetSummary in
            guard let data = response.data else { return BetSummary.init(unFinishedGames: 0, finishedGame: []) }
            let finishedGame = data.summaries.map { $0.toDateSummary() }
            return BetSummary(unFinishedGames: data.pendingTransactionCount, finishedGame: finishedGame)
        }
    }
    
    func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[SlotGroupedRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return slotApi.getSlotGameRecordByDate(date: localDate, offset: secondsToHours).map { (response) -> [SlotGroupedRecord] in
            guard let data = response.data else { return [] }
            let groupedDicts = Dictionary(grouping: data, by: { (element: SlotDateGameRecordBean) in
                return element.gameId
            })
            let groupedArray = groupedDicts.map { (gameId: Int32, gameList: [SlotDateGameRecordBean]) -> SlotDateGameRecordBean in
                return SlotDateGameRecordBean(gameId: gameId, gameList: gameList)
            }.sorted(by: {$0.endDate > $1.endDate })
            let records: [SlotGroupedRecord] = groupedArray.map({$0.toSlotGroupedRecord()})
            return records
        }
    }
    
    func getBetRecords(startDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32, offset: Int, take: Int) -> Single<CommonPage<SlotBetRecord>> {
        slotApi.getSlotBetRecordByPage(beginDate: startDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                                       endDate: endDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                                       gameId: gameId,
                                       offset: offset,
                                       take: take)
            .map { (response) -> CommonPage<SlotBetRecord> in
            guard let data = response.data else { return CommonPage(data: [], totalCount: 0) }
            return CommonPage(data: data.data.map { $0.toSlotBetRecord() }, totalCount: Int32(data.totalCount))
        }
    }
    
    func getUnsettledSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[SlotUnsettledSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return slotApi.getUnsettleGameSummary(offset: secondsToHours).map({ (response) in
            guard let data = response.data else { return []}
            return data.map({$0.toSlotUnsettledSummary()})
        })
    }
    
    func getUnsettledRecords(betTime: SharedBu.LocalDateTime, offset: Int, take: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
        return slotApi.getUnsettleGameRecords(date: betTime.toDateTimeFormatString(), offset: offset, take: take).map({ (response) in
            guard let data = response.data else { return CommonPage(data: [], totalCount: 0) }
            return CommonPage(data: data.data.map({$0.toSlotUnsettledRecord()}), totalCount: Int32(data.totalCount))
        })
    }
}
