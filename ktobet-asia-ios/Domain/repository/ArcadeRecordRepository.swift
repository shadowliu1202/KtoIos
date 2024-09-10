import Foundation
import RxSwift
import sharedbu

protocol ArcadeRecordRepository {
    func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<BetSummary>
    func getBetSummaryByDate(localDate: String, zoneOffset: sharedbu.UtcOffset, skip: Int, take: Int)
        -> Single<[GameGroupedRecord]>
    func getBetSummaryByGame(
        beginDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32,
        skip: Int,
        take: Int
    ) -> Single<[ArcadeGameBetRecord]>
    func getUnsettledSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[ArcadeUnsettledSummary]>
    func getUnsettledRecords(betTime: sharedbu.LocalDateTime) -> Single<[ArcadeUnsettledRecord]>
}

class ArcadeRecordRepositoryImpl: ArcadeRecordRepository {
    private let arcadeApi: ArcadeApi
    private let playerConfiguration: PlayerConfiguration
    private let httpClient: HttpClient

    init(
        _ arcadeApi: ArcadeApi,
        _ playerConfiguration: PlayerConfiguration,
        _ httpClient: HttpClient
    ) {
        self.arcadeApi = arcadeApi
        self.playerConfiguration = playerConfiguration
        self.httpClient = httpClient
    }

    func getBetSummary(zoneOffset: sharedbu.UtcOffset) -> Single<BetSummary> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getBetSummary(offset: secondsToHours).map { response -> BetSummary in
            guard let data = response else { return BetSummary(unFinishedGames: 0, finishedGame: []) }
            let finishedGame = try data.summaries.map { try $0.toDateSummary() }
            return BetSummary(unFinishedGames: 0, finishedGame: finishedGame)
        }
    }

    func getBetSummaryByDate(
        localDate: String,
        zoneOffset: sharedbu.UtcOffset,
        skip: Int,
        take: Int
    )
        -> Single<[GameGroupedRecord]>
    {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getGameRecordByDate(date: localDate, offset: secondsToHours, skip: skip, take: take)
            .map { response -> [GameGroupedRecord] in
                guard let data = response?.data else { return [] }
                return try data.map { try $0.toGameGroupedRecord(host: self.httpClient.host.absoluteString) }
            }
    }

    func getBetSummaryByGame(
        beginDate: sharedbu.LocalDateTime,
        endDate: sharedbu.LocalDateTime,
        gameId: Int32,
        skip: Int,
        take: Int
    )
        -> Single<[ArcadeGameBetRecord]>
    {
        arcadeApi
            .getBetRecords(
                beginDate: beginDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
                endDate: endDate.toQueryFormatString(timeZone: playerConfiguration.timezone()),
                gameId: gameId,
                skip: skip,
                take: take
            )
            .map { response -> [ArcadeGameBetRecord] in
                guard let data = response?.data else { return [] }
                return try data.map { try $0.toArcadeGameBetRecord() }
            }
    }

    func getUnsettledSummary(zoneOffset: sharedbu.UtcOffset) -> Single<[ArcadeUnsettledSummary]> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return arcadeApi.getUnsettleGameSummary(offset: secondsToHours).map { response in
            guard let data = response else { return [] }
            return try data.map { try $0.toUnsettledSummary() }
        }
    }

    func getUnsettledRecords(betTime: sharedbu.LocalDateTime) -> Single<[ArcadeUnsettledRecord]> {
        arcadeApi.getUnsettleGameRecords(date: betTime.toDateTimeFormatString())
            .map { [unowned self] response in
                guard let data = response else { return [] }
                return try data.map { bean in try bean.toUnsettledRecord(host: self.httpClient.host.absoluteString) }
            }
    }
}
