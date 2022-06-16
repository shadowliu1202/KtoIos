import Foundation
import RxSwift
import SharedBu

protocol P2PRecordRepository {
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[GameGroupedRecord]>
    func getBetSummaryByGame(beginDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32) -> Single<[P2PGameBetRecord]>
}

class P2PRecordRepositoryImpl: P2PRecordRepository {
    private var p2pApi: P2PApi!
    private var playerConfiguation: PlayerConfiguration!
    
    init(_ p2pApi: P2PApi, playerConfiguation: PlayerConfiguration) {
        self.p2pApi = p2pApi
        self.playerConfiguation = playerConfiguation
    }
    
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[DateSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return p2pApi.getBetSummary(offset: secondsToHours).map({ (response) -> [DateSummary] in
            guard let data = response.data else { return [] }
            return try data.summaries.map({ try $0.toDateSummary() })
        })
    }
    
    func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset) -> Single<[GameGroupedRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return p2pApi.getGameRecordByDate(date: localDate, offset: secondsToHours).map({ (response) -> [GameGroupedRecord] in
            guard let data = response.data else { return [] }
            let groupedDicts = Dictionary(grouping: data, by: { (element) in
                return element.gameGroupId
            })
            let groupedArray = groupedDicts.map { (gameGroupId: Int32, value: [P2PDateBetRecordBean]) -> P2PDateBetRecordBean in
                return P2PDateBetRecordBean(gameGroupId: gameGroupId, gameList: value)
            }.sorted(by: {$0.endDate > $1.endDate })
            let records: [GameGroupedRecord] = try groupedArray.map({ try $0.toGameGroupedRecord()})
            return records
        })
    }
    
    func getBetSummaryByGame(beginDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32) -> Single<[P2PGameBetRecord]> {
        p2pApi.getBetRecords(beginDate: beginDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                             endDate: endDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                             gameId: gameId).map { (response) -> [P2PGameBetRecord] in
            guard let data = response.data else { return [] }
            return try data.map({ try $0.toP2PGameBetRecord() })
        }
    }
    
}
