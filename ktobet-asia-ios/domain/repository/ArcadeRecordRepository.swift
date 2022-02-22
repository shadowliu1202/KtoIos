import Foundation
import RxSwift
import SharedBu

protocol ArcadeRecordRepository {
    func getBetSummary(zoneOffset: Kotlinx_datetimeUtcOffset) -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String, zoneOffset: Kotlinx_datetimeUtcOffset, skip: Int, take: Int) -> Single<[GameGroupedRecord]>
    func getBetSummaryByGame(beginDate: String, endDate: String, gameId: Int32, skip: Int, take: Int) -> Single<[ArcadeGameBetRecord]>
}


class ArcadeRecordRepositoryImpl: ArcadeRecordRepository {
    private var arcadeApi: ArcadeApi!
    
    init(_ arcadeApi: ArcadeApi) {
        self.arcadeApi = arcadeApi
    }
    
    func getBetSummary(zoneOffset: Kotlinx_datetimeUtcOffset) -> Single<[DateSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getBetSummary(offset: secondsToHours).map({ (response) -> [DateSummary] in
            guard let data = response.data else { return [] }
            return data.summaries.map({ $0.toDateSummary() })
        })
    }
    
    func getBetSummaryByDate(localDate: String, zoneOffset: Kotlinx_datetimeUtcOffset, skip: Int, take: Int) -> Single<[GameGroupedRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getGameRecordByDate(date: localDate, offset: secondsToHours, skip: skip, take: take).map({ (response) -> [GameGroupedRecord] in
            guard let data = response.data?.data else { return [] }
            return data.map({$0.toGameGroupedRecord()})
        })
    }
    
    func getBetSummaryByGame(beginDate: String, endDate: String, gameId: Int32, skip: Int, take: Int) -> Single<[ArcadeGameBetRecord]> {
        return arcadeApi.getBetRecords(beginDate: beginDate, endDate: endDate, gameId: gameId, skip: skip, take: take).map { (response) -> [ArcadeGameBetRecord] in
            guard let data = response.data?.data else { return [] }
            return data.map({ $0.toArcadeGameBetRecord() })
        }
    }
}
