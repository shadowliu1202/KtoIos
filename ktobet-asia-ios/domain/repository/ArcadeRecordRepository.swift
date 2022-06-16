import Foundation
import RxSwift
import SharedBu

protocol ArcadeRecordRepository {
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset, skip: Int, take: Int) -> Single<[GameGroupedRecord]>
    func getBetSummaryByGame(beginDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32, skip: Int, take: Int) -> Single<[ArcadeGameBetRecord]>
}


class ArcadeRecordRepositoryImpl: ArcadeRecordRepository {
    private var arcadeApi: ArcadeApi!
    private var playerConfiguation: PlayerConfiguration!
    
    init(_ arcadeApi: ArcadeApi, playerConfiguation: PlayerConfiguration) {
        self.arcadeApi = arcadeApi
        self.playerConfiguation = playerConfiguation
    }
    
    func getBetSummary(zoneOffset: SharedBu.UtcOffset) -> Single<[DateSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getBetSummary(offset: secondsToHours).map({ (response) -> [DateSummary] in
            guard let data = response.data else { return [] }
            return try data.summaries.map({ try $0.toDateSummary() })
        })
    }
    
    func getBetSummaryByDate(localDate: String, zoneOffset: SharedBu.UtcOffset, skip: Int, take: Int) -> Single<[GameGroupedRecord]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getGameRecordByDate(date: localDate, offset: secondsToHours, skip: skip, take: take).map({ (response) -> [GameGroupedRecord] in
            guard let data = response.data?.data else { return [] }
            return try data.map({ try $0.toGameGroupedRecord()})
        })
    }
    
    func getBetSummaryByGame(beginDate: SharedBu.LocalDateTime, endDate: SharedBu.LocalDateTime, gameId: Int32, skip: Int, take: Int) -> Single<[ArcadeGameBetRecord]> {
        arcadeApi.getBetRecords(beginDate: beginDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                                endDate: endDate.toQueryFormatString(timeZone: playerConfiguation.timezone()),
                                gameId: gameId,
                                skip: skip,
                                take: take)
            .map { (response) -> [ArcadeGameBetRecord] in
                guard let data = response.data?.data else { return [] }
                return try data.map({ try $0.toArcadeGameBetRecord() })
            }
    }
}
