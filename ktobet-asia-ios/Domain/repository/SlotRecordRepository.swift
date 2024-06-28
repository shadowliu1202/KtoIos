import Foundation
import RxSwift
import sharedbu

protocol SlotRecordRepository {
    func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<BetSummary>
    func getBetSummaryByDate(localDate: String, zoneOffset: sharedbu.UtcOffset) -> Single<[SlotGroupedRecord]>
    func getBetRecords(startDate: sharedbu.LocalDateTime, endDate: sharedbu.LocalDateTime, gameId: Int32, offset: Int, take: Int)
        -> Single<CommonPage<SlotBetRecord>>
    func getUnsettledSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[SlotUnsettledSummary]>
    func getUnsettledRecords(betTime: sharedbu.LocalDateTime, offset: Int, take: Int) -> Single<CommonPage<SlotUnsettledRecord>>
}

class SlotRecordRepositoryImpl: SlotRecordRepository {
    private let slotApi: SlotApi
    private let playerConfiguration: PlayerConfiguration
    private let httpClient: HttpClient

    init(
        _ slotApi: SlotApi,
        _ playerConfiguration: PlayerConfiguration,
        _ httpClient: HttpClient)
    {
        self.slotApi = slotApi
        self.playerConfiguration = playerConfiguration
        self.httpClient = httpClient
    }

    func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<BetSummary> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return slotApi.getSlotBetSummary(offset: secondsToHours).map { response -> BetSummary in
            guard let data = response else { return BetSummary(unFinishedGames: 0, finishedGame: []) }
            let finishedGame = try data.summaries.map { try $0.toDateSummary() }
            return BetSummary(unFinishedGames: data.pendingTransactionCount, finishedGame: finishedGame)
        }
    }

    func getBetSummaryByDate(localDate: String, zoneOffset: sharedbu.UtcOffset) -> Single<[SlotGroupedRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return slotApi.getSlotGameRecordByDate(date: localDate, offset: secondsToHours)
            .map { [unowned self] response -> [SlotGroupedRecord] in
                guard let data = response else { return [] }
                let groupedDicts = Dictionary(grouping: data, by: { (element: SlotDateGameRecordBean) in
                    element.gameId
                })
                let groupedArray = groupedDicts.map { (
                    gameId: Int32,
                    gameList: [SlotDateGameRecordBean]) -> SlotDateGameRecordBean in
                    SlotDateGameRecordBean(gameId: gameId, gameList: gameList)
                }.sorted(by: { $0.endDate > $1.endDate })
                let records: [SlotGroupedRecord] = try groupedArray
                    .map({ try $0.toSlotGroupedRecord(host: self.httpClient.host.absoluteString) })
                return records
            }
    }

    func getBetRecords(
        startDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32,
        offset: Int,
        take: Int)
        -> Single<CommonPage<SlotBetRecord>>
    {
        slotApi
            .getSlotBetRecordByPage(
                beginDate: startDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
                endDate: endDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
                gameId: gameId,
                offset: offset,
                take: take)
            .map { response -> CommonPage<SlotBetRecord> in
                guard let data = response else { return CommonPage(data: [], totalCount: 0) }
                return try CommonPage(data: data.data.map { try $0.toSlotBetRecord() }, totalCount: Int32(data.totalCount))
            }
    }

    func getUnsettledSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[SlotUnsettledSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return slotApi.getUnsettleGameSummary(offset: secondsToHours).map({ response in
            guard let data = response else { return [] }
            return try data.map({ try $0.toSlotUnsettledSummary() })
        })
    }

    func getUnsettledRecords(betTime: sharedbu.LocalDateTime, offset: Int, take: Int) -> Single<CommonPage<SlotUnsettledRecord>> {
        slotApi.getUnsettleGameRecords(date: betTime.toDateTimeFormatString(), offset: offset, take: take)
            .map({ [unowned self] response in
                guard let data = response else { return CommonPage(data: [], totalCount: 0) }
                return try CommonPage(
                    data: data.data.map({ try $0.toSlotUnsettledRecord(host: self.httpClient.host.absoluteString) }),
                    totalCount: Int32(data.totalCount))
            })
    }
}
