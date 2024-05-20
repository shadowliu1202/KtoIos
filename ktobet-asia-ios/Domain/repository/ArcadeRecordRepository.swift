import Foundation
import RxSwift
import sharedbu

protocol ArcadeRecordRepository {
    func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[DateSummary]>
    func getBetSummaryByDate(localDate: String, zoneOffset: sharedbu.UtcOffset, skip: Int, take: Int)
        -> Single<[GameGroupedRecord]>
    func getBetSummaryByGame(
        beginDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32,
        skip: Int,
        take: Int) -> Single<[ArcadeGameBetRecord]>
}

class ArcadeRecordRepositoryImpl: ArcadeRecordRepository {
    private let arcadeApi: ArcadeApi
    private let playerConfiguration: PlayerConfiguration
    private let httpClient: HttpClient

    init(
        _ arcadeApi: ArcadeApi,
        _ playerConfiguration: PlayerConfiguration,
        _ httpClient: HttpClient)
    {
        self.arcadeApi = arcadeApi
        self.playerConfiguration = playerConfiguration
        self.httpClient = httpClient
    }

    func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[DateSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getBetSummary(offset: secondsToHours).map({ response -> [DateSummary] in
            guard let data = response.data else { return [] }
            return try data.summaries.map({ try $0.toDateSummary() })
        })
    }

    func getBetSummaryByDate(
        localDate: String,
        zoneOffset: sharedbu.UtcOffset,
        skip: Int,
        take: Int)
        -> Single<[GameGroupedRecord]>
    {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getGameRecordByDate(date: localDate, offset: secondsToHours, skip: skip, take: take)
            .map({ response -> [GameGroupedRecord] in
                guard let data = response.data?.data else { return [] }
                return try data.map({ try $0.toGameGroupedRecord(host: self.httpClient.host.absoluteString) })
            })
    }

    func getBetSummaryByGame(
        beginDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32,
        skip: Int,
        take: Int)
        -> Single<[ArcadeGameBetRecord]>
    {
        arcadeApi
            .getBetRecords(
                beginDate: beginDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
                endDate: endDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
                gameId: gameId,
                skip: skip,
                take: take)
            .map { response -> [ArcadeGameBetRecord] in
                guard let data = response.data?.data else { return [] }
                return try data.map({ try $0.toArcadeGameBetRecord() })
            }
    }
}
