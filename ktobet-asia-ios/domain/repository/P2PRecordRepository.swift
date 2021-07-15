import Foundation
import RxSwift
import SharedBu

protocol P2PRecordRepository {
    func getBetSummary(zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[GameGroupedRecord]>
    func getBetSummaryByGame(beginDate: String, endDate: String, gameId: Int32) -> Single<[P2PGameBetRecord]>
}

class P2PRecordRepositoryImpl: P2PRecordRepository {
    private var p2pApi: P2PApi!
    
    init(_ p2pApi: P2PApi) {
        self.p2pApi = p2pApi
    }
    
    func getBetSummary(zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[DateSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return p2pApi.getBetSummary(offset: secondsToHours).map({ (response) -> [DateSummary] in
            guard let data = response.data else { return [] }
            return data.summaries.map({ $0.toDateSummary() })
        })
    }
    
    func getBetSummaryByDate(localDate: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<[GameGroupedRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return p2pApi.getGameRecordByDate(date: localDate, offset: secondsToHours).map({ (response) -> [GameGroupedRecord] in
            guard let data = response.data else { return [] }
            let groupedDicts = Dictionary(grouping: data, by: { (element) in
                return element.gameGroupId
            })
            let groupedArray = groupedDicts.map { (gameGroupId: Int32, value: [P2PDateBetRecordBean]) -> P2PDateBetRecordBean in
                return P2PDateBetRecordBean(gameGroupId: gameGroupId, gameList: value)
            }.sorted(by: {$0.endDate > $1.endDate })
            let records: [GameGroupedRecord] = groupedArray.map({$0.toGameGroupedRecord()})
            return records
        })
    }
    
    func getBetSummaryByGame(beginDate: String, endDate: String, gameId: Int32) -> Single<[P2PGameBetRecord]> {
        return p2pApi.getBetRecords(beginDate: beginDate, endDate: endDate, gameId: gameId).map { (response) -> [P2PGameBetRecord] in
            guard let data = response.data else { return [] }
            return data.map({ $0.toP2PGameBetRecord() })
        }
    }
    
}
